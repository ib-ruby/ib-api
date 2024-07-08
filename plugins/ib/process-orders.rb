module IB
=begin

Plugin for a comfortable processing of orders

Public API
==========

Extends IB::Connection

* initialize_order_handling

  subscribes to various tws-messages and keeps record of the order-state

* request_open_orders

  (aliased as UpdateOrders) erases account.orders and requests open-orders from the TWS
  and populates Account#Orders

=end
  module ProcessOrders
  def initialize_order_handling

    subscribe( :CommissionReport, :ExecutionData, :OrderStatus, :OpenOrder, :OpenOrderEnd, :NextValidId ) do |msg|
      case msg

      when IB::Messages::Incoming::CommissionReport
        # Commission-Reports are not assigned to a order -
        logger.info "CommissionReport -------#{msg.exec_id} :...:C: #{msg.commission} :...:P/L: #{msg.realized_pnl}-"
      when IB::Messages::Incoming::OrderStatus

        # The order-state only links via local_id and perm_id to orders.
        # There is no reference to a contract or an account

        success = update_order_dependent_object( msg.order_state) do |o|
          o.order_states.save_insert msg.order_state, :status
        end

        logger.warn {  "Order State not assigned-- #{msg.order_state.to_human} ----------" } if success.nil?

      when IB::Messages::Incoming::OpenOrder
        account_data(msg.order.account) do | this_account |
          # first update the contracts
          # make open order equal to IB::Spreads (include negativ con_id)
          msg.contract[:con_id] = -msg.contract.combo_legs.map{|y| y.con_id}.sum  if msg.contract.is_a? IB::Bag
          msg.contract.orders.save_insert msg.order, :local_id
          this_account.contracts.save_insert msg.contract, :con_id, false
          # now save the order-record
          msg.order.contract = msg.contract
          this_account.orders.save_insert msg.order, :local_id
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
            o.order_states << IB::OrderState.new( perm_id: o.perm_id,
                                                 local_id: o.local_id,
                                                   status: 'Filled' )
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

        logger.warn { "Execution-Record not assigned-- #{msg.execution.to_human} ----------" } if success.nil?

      end  # case msg.code
    end # do
  end # def subscribe

  # Resets the order-array for each account.
  # Requests all open (eg. pending)  orders from the tws
  #
  # Waits until the OpenOrderEnd-Message is received


  def request_open_orders

    q =  Queue.new
    subscription = subscribe( :OpenOrderEnd ) { q.push(true) }  # signal succsess
    account_data {| account | account.orders = [] }
    send_message :RequestAllOpenOrders
    ## the OpenOrderEnd-message usually appears after 0.1 sec.
    ## we wait for 1 sec.
    th =  Thread.new{   sleep 1 ; q.close  }

    q.pop # wait for OpenOrderEnd or finishing of thread

    unsubscribe subscription
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

  private
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
                a.locate_order local_id: order_dependent_object.local_id
              else
                a.locate_order perm_id: order_dependent_object.perm_id
              end
      yield order if order.present?
    end
  end


end # module

class Connection
  include ProcessOrders
end
Connection.current.activate_plugin 'managed-accounts'
Connection.current.initialize_managed_accounts!
Connection.current.initialize_order_handling!

end   ##  module IB

