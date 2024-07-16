module IB


  class PriceCondition < OrderCondition
    using IB::Support   # refine Array-method for decoding of IB-Messages
    include BaseProperties
    prop :price,
      :trigger_method  # see /models/ib/order.rb# 51 ff  and /lib/ib/constants # 210 ff

    def default_attributes
      super.merge( :trigger_method => :default  )
    end

    def condition_type
    1
    end

    def self.make  buffer
         m= self.new  conjunction_connection:  buffer.read_string,
          operator: buffer.read_int,
          price: buffer.read_decimal

          the_contract = IB::Contract.new con_id: buffer.read_int, exchange: buffer.read_string
          m.contract = the_contract
          m.trigger_method = buffer.read_int
          m

      end

    def serialize
    super << self[:operator] << price << serialize_contract_by_con_id <<  self[:trigger_method]
    end

    # dsl:   PriceCondition.fabricate some_contract, ">=", 500
    def self.fabricate contract, operator, price
      error "Condition Operator has to be \">=\" or \"<=\" " unless ["<=", ">="].include? operator
      self.new  operator: operator,
                price: price.to_i,
                contract: verify_contract_if_necessary( contract )
    end

  end

end # module
