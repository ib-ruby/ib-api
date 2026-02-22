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

end # module
