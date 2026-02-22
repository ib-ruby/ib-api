module IB
  class ExecutionCondition < OrderCondition
    using IB::Support   # refine Array-method for decoding of IB-Messages
    
    def condition_type 
      5
    end

    def self.make  buffer
      m =self.new  conjunction_connection:  buffer.read_string,
                   operator: buffer.read_int

      the_contract = IB::Contract.new sec_type: buffer.read_string,
                                      exchange: buffer.read_string,
                                      symbol: buffer.read_string
      m.contract = the_contract
      m
    end

    def serialize
      super << contract[:sec_type] <<(contract.primary_exchange.presence || contract.exchange) << contract.symbol
    end
  
    def self.fabricate contract
      self.new contract: verify_contract_if_necessary( contract )
    end

  end


end # module
