module IB




  class PercentChangeCondition < OrderCondition
    using IB::Support   # refine Array-method for decoding of IB-Messages
    prop :percent_change
    include BaseProperties

    def condition_type
    7
    end

    def self.make  buffer
        m = self.new  conjunction_connection:  buffer.read_string,
                      operator: buffer.read_int,
                      percent_change: buffer.read_decimal

        the_contract = IB::Contract.new con_id: buffer.read_int, exchange: buffer.read_string
        m.contract = the_contract
        m
    end

    def serialize
      super << self[:operator] << percent_change  << serialize_contract_by_con_id 

    end
    # dsl:   PercentChangeCondition.fabricate some_contract, ">=", "5%"
    def self.fabricate contract, operator, change
      error "Condition Operator has to be \">=\" or \"<=\" " unless ["<=", ">="].include? operator
        self.new  operator: operator,
                  percent_change: change.to_i,
                  contract: verify_contract_if_necessary( contract )
    end
  end
end # module
