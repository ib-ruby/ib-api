module IB
=begin

Plugin that provides helper methods for orders

Requires  activation of the `verify`-Plugin

Extends IB::Order

Changes the IB::Order-object


Public API
==========

* auto_adjust

Standard usage

```ruby
c =  IB::Stock.new symbol 'GE'
o =  IB::Limit.order contract: c, price: 150.0998, size: 100
o.auto_adjust

o.limit_price  => 151.1

```
=end

  module AutoAdjust

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
  end
  class Order
    include AutoAdjust
  end  # class Order
end  # module
