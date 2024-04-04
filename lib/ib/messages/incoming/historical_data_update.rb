
module IB
  module Messages
    module Incoming

      HistoricalDataUpdate = def_message [90, 0] ,
                             [:request_id, :int] ,
                             [:count, :int],
                             [:bar, :bar]  # defined in support.rb

      class HistoricalDataUpdate
        attr_accessor :results
				using IB::Support  # extended Array-Class  from abstract_message

        def bar
            @bar = IB::Bar.new @data[:bar]
          end

        def to_human
          "<HistDataUpdate #{request_id} #{bar}>"
        end
      end
#https://github.com/wizardofcrowds/ib-api/blob/3dd4851c838f61b2a6bbdc98a36b99499f90b701/lib/ib/messages/incoming/historical_data.rb  HistoricalDataUpdate = def_message [90,0],
#                                   [:request_id, :int],
#                                   [:_, :int]
#      # ["90", "2", "-1", "1612238280", "1.28285", "1.28275", "1.28285", "1.28275", "-1.0", "-1"]
#      class HistoricalDataUpdate
#        attr_accessor :results
#        using IBSupport  # extended Array-Class  from abstract_message
#
#        def load
#          super
#          # See Rust impl at https://github.com/sparkstartconsulting/IBKR-API-Rust/blob/d4e89c39a57a2b448bb912196ebc42acfb915be7/src/core/decoder.rs#L1097
#          @results = [ IB::Bar.new(:time => buffer.read_int_date,
#                                   :open => buffer.read_decimal,
#                                   :close => buffer.read_decimal,
#                                   :high => buffer.read_decimal,
#                                   :low => buffer.read_decimal,
#                                   :wap => buffer.read_decimal,
#                                   :volume => buffer.read_int) ]
#        end
#
#        def to_human
#          "<HistoricalDataUpdate: #{request_id} #{@results.inspect}>"
#        end
#end # HistoricalDataUpdate

    end # module Incoming
  end # module Messages
end # module IB
