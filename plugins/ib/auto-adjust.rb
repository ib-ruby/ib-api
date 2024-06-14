
module IB
  module AutoAdjust


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
    # ATTENTION: The method mutates the Order-Object.
    #
    # | min-tick     |  round     |
    # |--------------|------------|
    # |   10         |   110      |
    # |    1         |   111      |
    # |    0.1       |   111.1    |
    # |    0.01      |   111.11   |
    # |    0.001     |   111.111  |
    # |    0.0001    |   111.1111 |
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
        # ensure that contract_details are present

        min_tick = contract.then{ |y| y.contract_detail.is_a?( IB::ContractDetail ) ? y.contract_detail.min_tick : y.verify.first.contract_detail.min_tick }
        # there are two attributes to consider: limit_price and aux_price
        # limit_price +  aux_price may be nil or an empty string. Then ".to_f.zero?" becomes true 
        self.limit_price= adjust_price.call(limit_price.to_f, min_tick) unless limit_price.to_f.zero?
        self.aux_price= adjust_price.call(aux_price.to_f, min_tick) unless aux_price.to_f.zero?
      end
    end
  end
  class Order
    include AutoAdjust
  end  # class Order
end  # module
