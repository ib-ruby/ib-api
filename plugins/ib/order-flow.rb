module IB

=begin

Plugin to support a simple Order-Flow

Public API
==========

Extends IB::Order

* check_margin
  * depends on a previously submitted `what-if' order
  * on success it returns the order-object for further processing, otherwise nil.
* place
  * submit the order
  * return a order-object for further processing
* modify
  * modify price or quantity of the submitted order
* cancel
  * submit a cancel request

=end
 module OrderFlow
    # Placement
    #
    # The Order is only placed, if local_id is not set
    #
    # Modifies the Order-Object and returns the assigned local_id
    def place the_contract=nil
      connection = IB::Connection.current
      error "Unable to place order, next_local_id not known" unless connection.next_local_id
      error "local_id present. Order is already placed.  Do you want to modify?"  unless  local_id.nil?
      self.client_id = connection.client_id
      self.local_id = connection.next_local_id
      connection.next_local_id += 1
      self.placed_at = Time.now
      modify the_contract, self.placed_at
      self
    end

    # Modify Order (convenience wrapper for send_message :PlaceOrder). Returns local_id.
    def modify the_contract=nil, time=Time.now
      error "Unable to modify order; local_id not specified" if local_id.nil?
      the_contract =  contract if the_contract.nil?
      error "Unable to place order, contract has to be specified" unless the_contract.is_a?( IB::Contract )

      connection = IB::Connection.current
      self.modified_at = time
      connection.send_message :PlaceOrder,
                              :order => self,
                              :contract => if the_contract.con_id.to_i > 0
                                               Contract.new con_id: the_contract.con_id,
                                                          exchange: the_contract.exchange
                                            else
                                               the_contract
                                            end
                              :local_id => local_id
      local_id  # return the local_id
    end

    # returns the order if the margin-requirements are met
    #
    # typical setup
    # ```ruby
    #  ib =  IB::Connection.new
    #  ib.activate_plugin ...
    #  u =  ib.clients.last
    #  submitted_order = u.preview( order: some_order, contract: some_contract ) .check_margin( 0.25 ) &.place
    # ```
    def check_margin treshold = 0.1
      error "Unable to check margin, forcast is not initialized" if order_state.nil or order_state.forecast[ :init_margin ].nil?
      ib =  Connection.current
      client =  ib.clients.find{|y| y.account == account}
      net_liquidation =  client.account_data_scan( /NetLiquidation$/ ).first.value.to_i
      buffer = order_state.forcast.then{ |x| x[ :equity_with_loan ] - x[ :init_margin ] }
      buffer > net_liquidation * treshold ?  self : nil
    end
    #
    # Auto Adjust implements a simple algorithm  to ensure that an order is accepted

    # It reads `contract_detail.min_tick`.
    #
    # For min-tick smaller then 0.01, the value is rounded to the next higer digit.
    #
    # The method mutates the Order-Object.
    #
    # | min-tick     |  round     |
    # |--------------|------------|
    # |   10         |   110      |
    # |    1         |   111      |
    # |    0.1       |   111.1    |
    # |    0.01      |   111.11   |
    # |    0.001     |   111.111  |
    # |    0.0001    |   111.111  |
    # |--------------|------------|
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

        min_tick = contract.then{ |y| y.contract_detail.is_a?( IB::ContractDetail ) ? y.contract_detail.min_tick : y.verify.first.contract_detail.min_tick }
        # there are two attributes to consider: limit_price and aux_price
        # limit_price +  aux_price may be nil or an empty string. Then ".to_f.zero?" becomes true
        self.limit_price= adjust_price.call(limit_price.to_d, min_tick) unless limit_price.to_f.zero?
        self.aux_price= adjust_price.call(aux_price.to_d, min_tick) unless aux_price.to_f.zero?
      end
    end

 end # module OrderFlow

  class Order
    include OrderFlow
  end  # class
  Connection.current.activate_plugin 'process-orders'
end # module IB
