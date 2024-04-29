
module IB
  module ProcessOrders
=begin
UpdateOrderDependingObject

Generic method which enables operations on the order-Object,
which is associated to OrderState-, Execution-, CommissionReport-
events fired by the tws.
The order is identified by local_id and perm_id

Everything is carried out in a mutex-synchonized environment
=end
  def update_order_dependent_object order_dependent_object  # :nodoc:
   account_data  do  | a |
      order = if order_dependent_object.local_id.present?
                a.locate_order( :local_id => order_dependent_object.local_id)
              else
                a.locate_order( :perm_id => order_dependent_object.perm_id)
              end
      yield order if order.present?
    end
  end
  def initialize_order_handling
    tws.subscribe( :CommissionReport, :ExecutionData, :OrderStatus, :OpenOrder, :OpenOrderEnd, :NextValidId ) do |msg|
      case msg

      when IB::Messages::Incoming::CommissionReport
        # Commission-Reports are not assigned to a order -
        logger.info "CommissionReport -------#{msg.exec_id} :...:C: #{msg.commission} :...:P/L: #{msg.realized_pnl}-"
      when IB::Messages::Incoming::OrderStatus

        # The order-state only links via local_id and perm_id to orders.
        # There is no reference to a contract or an account

        success = update_order_dependent_object( msg.order_state) do |o|
          o.order_states.update_or_create msg.order_state, :status
        end

        logger.info {  "Order State not assigned-- #{msg.order_state.to_human} ----------" } if success.nil?

      when IB::Messages::Incoming::OpenOrder
        account_data(msg.order.account) do | this_account |
          # first update the contracts
          # make open order equal to IB::Spreads (include negativ con_id)
          msg.contract[:con_id] = -msg.contract.combo_legs.map{|y| y.con_id}.sum  if msg.contract.is_a? IB::Bag
          msg.contract.orders.update_or_create msg.order, :local_id
          this_account.contracts.first_or_create msg.contract, :con_id
          # now save the order-record
          msg.order.contract = msg.contract
          this_account.orders.update_or_create msg.order, :local_id
        end

        #     update_ib_order msg  ## aus support
      when IB::Messages::Incoming::OpenOrderEnd
        #             exitcondition=true
        logger.debug { "OpenOrderEnd" }

      when IB::Messages::Incoming::ExecutionData
        # Excution-Data are fired independly from order-states.
        # The Objects are stored at the associated order
        success = update_order_dependent_object( msg.execution) do |o|
          o.executions << msg.execution
          if msg.execution.cumulative_quantity.to_i == o.total_quantity.abs
            logger.info{ "#{o.account} --> #{o.contract.symbol}: Execution completed" }
            o.order_states.first_or_create( IB::OrderState.new( perm_id: o.perm_id,
                                                               local_id: o.local_id,
                                                               status: 'Filled' ), :status )
            # update portfoliovalue
            a = @accounts.detect{ | x | x.account == o.account } #  we are in a mutex controlled environment
            pv = a.portfolio_values.detect{ | y | y.contract.con_id == o.contract.con_id}
            change = o.action == :sell ? -o.total_quantity : o.total_quantity
            if pv.present?
              pv.update_attribute :position, pv.position + change
            else
              a.portfolio_values << IB::PortfolioValue.new( position: change, contract: o.contract )
            end
          else
            logger.debug{ "#{o.account} --> #{o.contract.symbol}: Execution not completed (#{msg.execution.cumulative_quantity.to_i}/#{o.total_quantity.abs})" }
          end  # branch
        end # block

        logger.error { "Execution-Record not assigned-- #{msg.execution.to_human} ----------" } if success.nil?

      end  # case msg.code
    end # do
  end # def subscribe

  # Resets the order-array for each account.
  # Requests all open (eg. pending)  orders from the tws
  #
  # Waits until the OpenOrderEnd-Message is received


  def request_open_orders

    q =  Queue.new
    subscription = tws.subscribe( :OpenOrderEnd ) { q.push(true) }  # signal succsess
    account_data {| account | account.orders = [] }
    send_message :RequestAllOpenOrders
    ## the OpenOrderEnd-message usually appears after 0.1 sec.
    ## we wait for 1 sec.
    th =  Thread.new{   sleep 1 ; q.close  }

    q.pop # wait for OpenOrderEnd or finishing of thread

    tws.unsubscribe subscription
    if q.closed?
      5.times do
      logger.fatal { "Is the API in read-only modus?  No Open Order Message received! "}
      sleep  0.2
      end
    else
      Thread.kill(th)
      q.close
      account_data {| account | account.orders } # reset order array
    end
  end

  alias update_orders request_open_orders




end # module

class Connection
  inlcude ProcessOrders
end

end   ##  module IB


module IB

  class Order
    # Auto Adjust implements a simple algorithm  to ensure that an order is accepted

    # It reads `contract_detail.min_tick`.
    # #
    # If min_tick < 0.01, the real tick-increments differ fron the min_tick_value
    #
    # For J36 (jardines) min tick is 0.001, but the minimal increment is 0.005
    # For Tui1 its the samme, min_tick is 0.00001 , minimal increment ist 0.00005
    #
    # Thus, for min-tick smaller then 0.01, the value is rounded to the next higer digit.
    #
    # | min-tick     |  round     |
    # |--------------|------------|
    # |   10         |   110      |
    # |    1         |   111      |
    # |    0.1       |   111.1    |
    # |    0.001     |   111.11   |
    # |    0.0001    |   111.11   |
    # |    0.00001   |   111.111  |
    #
    |--------------|------------|
    #
    def auto_adjust
      # lambda to perform the calculation
      adjust_price = ->(a,b) do
        count = -Math.log10(b).round.to_i
        count = count -1 if count > 2
        a.round count

      end


      error "No Contract provided to Auto adjust" unless contract.is_a? IB::Contract

      unless contract.is_a? IB::Bag
        # ensure that contract_details are present

        min_tick = contract.verify.first.contract_detail.min_tick
        # there are two attributes to consider: limit_price and aux_price
        # limit_price +  aux_price may be nil or an empty string. Then ".to_f.zero?" becomes true 
        self.limit_price= adjust_price.call(limit_price.to_f, min_tick) unless limit_price.to_f.zero?
        self.aux_price= adjust_price.call(aux_price.to_f, min_tick) unless aux_price.to_f.zero?
      end
    end
  end  # class Order
end  # module
