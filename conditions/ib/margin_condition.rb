module IB



  class MarginCondition < OrderCondition
    using IB::Support   # refine Array-method for decoding of IB-Messages

    prop  :percent

    def condition_type 
      4
    end

    def self.make  buffer
      self.new  conjunction_connection:  buffer.read_string,
                operator: buffer.read_int,
                percent: buffer.read_int

    end

    def serialize
    super << self[:operator] << percent 
    end
    def self.fabricate operator,  percent
      error "Condition Operator has to be \">=\" or \"<=\" " unless ["<=", ">="].include? operator 
      self.new operator: operator, 
              percent: percent
    end
  end
  

  class VolumeCondition < OrderCondition
    using IB::Support   # refine Array-method for decoding of IB-Messages

    prop :volume

    def condition_type 
    6
    end

    def self.make  buffer
      m = self.new  conjunction_connection:  buffer.read_string,
                    operator: buffer.read_int,
                    volumne: buffer.read_int

      the_contract = IB::Contract.new con_id: buffer.read_int, exchange: buffer.read_string
      m.contract = the_contract
      m
    end

    def serialize

      super << self[:operator] << volume <<  serialize_contract_by.con_id 
    end

    # dsl:   VolumeCondition.fabricate some_contract, ">=", 50000
    def self.fabricate contract, operator, volume
      error "Condition Operator has to be \">=\" or \"<=\" " unless ["<=", ">="].include? operator 
      self.new  operator: operator,
                volume: volume,
                contract: verify_contract_if_necessary( contract )
    end
  end

  class PercentChangeCondition < OrderCondition
    using IB::Support   # refine Array-method for decoding of IB-Messages
    prop :percent_change

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
  class OrderCondition
    using IB::Support   # refine Array-method for decoding of IB-Messages
    # subclasses representing specialized condition types.

    Subclasses = Hash.new(OrderCondition)
    Subclasses[1] = IB::PriceCondition
    Subclasses[3] = IB::TimeCondition
    Subclasses[5] = IB::ExecutionCondition
    Subclasses[4] = IB::MarginCondition
    Subclasses[6] = IB::VolumeCondition
    Subclasses[7] = IB::PercentChangeCondition


    # This builds an appropriate subclass based on its type
    #
    def self.make_from  buffer
      condition_type = buffer.read_int
      OrderCondition::Subclasses[condition_type].make( buffer )
    end
  end  # class
end # module
