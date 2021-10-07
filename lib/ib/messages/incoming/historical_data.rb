module IB
  module Messages
    module Incoming

      # HistoricalData contains following @data:
			#
      # _General_:
			#
      # - request_id - The ID of the request to which this is responding
      # - count - Number of Historical data points returned (size of :results).
      # - results - an Array of Historical Data Bars
      # - start_date - beginning of returned Historical data period
      # - end_date   - end of returned Historical data period
      # 
			# Each returned Bar in @data[:results] Array contains this data:
      # - date - The date-time stamp of the start of the bar. The format is set to sec since EPOCHE
      #                                                       in outgoing/bar_requests  ReqHistoricalData.
      # - open -  The bar opening price.
      # - high -  The high price during the time covered by the bar.
      # - low -   The low price during the time covered by the bar.
      # - close - The bar closing price.
      # - volume - The volume during the time covered by the bar.
      # - trades - When TRADES historical data is returned, represents number of trades
      #   that occurred during the time period the bar covers
      # - wap - The weighted average price during the time covered by the bar.


      HistoricalData = def_message [17,0],
                                   [:request_id, :int],
                                   [:start_date, :datetime],
                                   [:end_date, :datetime],
                                   [:count, :int]
      class HistoricalData
        attr_accessor :results
				using IBSupport  # extended Array-Class  from abstract_message
 
        def load
          super

          @results = Array.new(@data[:count]) do |_|
            IB::Bar.new :time => buffer.read_int_date, # conversion of epoche-time-integer to Dateime
																											 # requires format_date in request to be "2"
																											 # (outgoing/bar_requests # RequestHistoricalData#Encoding)
                        :open => buffer.read_float,
                        :high => buffer.read_float,
                        :low => buffer.read_float,
                        :close => buffer.read_float,
                        :volume => buffer.read_int,
                        :wap => buffer.read_float,   
#                        :has_gaps => buffer.read_string,  # only in ServerVersion  < 124
                        :trades => buffer.read_int  
          end
        end

        def to_human
          "<HistoricalData: #{request_id}, #{count} items, #{start_date} to #{end_date}>"
        end
      end # HistoricalData


				HistogramData  = def_message( [89,0], 
																	[:request_id, :int], 
																	[ :number_of_points , :int ]) do
																		# to human
          "<HistogramData: #{request_id}, #{number_of_points} read>"
																	end

      class HistogramData
        attr_accessor :results
				using IBSupport  # extended Array-Class  from abstract_message
 
        def load
          super

          @results = Array.new(@data[:number_of_points]) do |_|
						{ price:  buffer.read_decimal, 
						 count: buffer.read_int }
					end
				end
			end

      HistoricalDataUpdate = def_message [90, 0] ,
                             [:request_id, :int] ,
                             [:count, :int],
                             [:bar, :bar]  # defined in support.rb

      class HistoricalDataUpdate
        attr_accessor :results
				using IBSupport  # extended Array-Class  from abstract_message

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
