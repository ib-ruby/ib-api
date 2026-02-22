module IB
  module Messages
    module Incoming
      extend Messages # def_message macros

      TickByTick =  def_message [99, 0], [:ticker_id, :int ],
      [ :tick_type, :int],
      [ :time, :int_date ]

      ## error messages: (10189) "Failed to request tick-by-tick data:Historical data request pacing violation"
      #
      class TickByTick
        using IB::Support  # extended Array-Class  from abstract_message
        def resolve_mask
          @data[:mask].present? ? [ @data[:mask] & 1 , @data[:mask] & 2  ] : []
        end

        def load
          super
          case @data[:tick_type ]
                      when 0
                        # do nothing
                      when 1, 2 # Last, AllLast
              load_map  [ :price, :decimal ]  ,
                        [ :size, :int ] ,
                        [ :mask, :int ] ,
                        [ :exchange, :string ],
                        [ :special_conditions, :string ]
                      when 3  # bid/ask
              load_map  [ :bid_price, :decimal ],
                        [ :ask_price, :decimal],
                        [ :bid_size, :int ],
                        [ :ask_size, :int] ,
                        [ :mask, :int  ]
                      when 4
              load_map  [ :mid_point, :decimal ]
                      end

          @out_labels = case @data[ :tick_tpye ]
                      when 1, 2
                        [ "PastLimit", "Unreported" ]
                        when 3
                        [ "BitPastLow", "BidPastHigh" ]
                        else
                          []
                        end
        end
        def to_human
          "< TickByTick:" + case @data[ :tick_type ]
          when 1,2
            "(Last) #{size} @ #{price} [#{exchange}] "
          when 3
            "(Bid/Ask) #{bid_size} @ #{bid_price} / #{ask_size } @ #{ask_price} "
          when 4
            "(Midpoint)  #{mid_point } "
          else
            ""
          end +  @out_labels.zip(resolve_mask).join( "/" )
        end

        [:price, :size, :mask, :exchange, :specialConditions, :bid_price, :ask_price, :bid_size, :ask_size, :mid_point].each do |name|
          define_method name do
            @data[name]
          end
        end
      # def method_missing method, *args
      #   if @data.keys.include? method
      #     @data[method]
      #   else
      #     error "method #{method} not known"
      #   end
      # end
      end
    end
  end
end

