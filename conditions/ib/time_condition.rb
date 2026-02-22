module IB


  class TimeCondition < OrderCondition
    using IB::Support   # refine Array-method for decoding of IB-Messages
    include BaseProperties
    prop :time

    def condition_type
      3
    end

    def self.make  buffer
      self.new  conjunction_connection:  buffer.read_string,
        operator: buffer.read_int,
        time: buffer.read_parse_date
    end

    def serialize
      t =  self[:time]
      if t.is_a?(String) && t =~ /^\d{8}\z/  # expiry-format yyymmmdd
        self.time = DateTime.new t[0..3],t[4..5],t[-2..-1]
      end
      serialized_time = case self[:time]   # explicity formatting of time-object
                        when String
                          self[:time]
                        when DateTime 
                          self[:time].gmtime.strftime("%Y%m%d %H:%M:%S %Z")
                        when  Date, Time
                          self[:time].strftime("%Y%m%d %H:%M:%S")
                        end

      super << self[:operator] << serialized_time
    end

    def self.fabricate operator, time
      self.new operator: operator,
              time: time
    end
  end

end # module
