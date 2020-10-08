module IB
  module Messages
    module Incoming
      MarketDepth =
        def_message 12, %i[request_id int],
                    %i[position int], # The row Id of this market depth entry.
                    %i[operation int], # How it should be applied to the market depth:
                    #   0 = insert this new order into the row identified by :position
                    #   1 = update the existing order in the row identified by :position
                    #   2 = delete the existing order at the row identified by :position
                    %i[side int], # side of the book: 0 = ask, 1 = bid
                    %i[price decimal],
                    %i[size int]

      class MarketDepth
        def side
          @data[:side] == 0 ? :ask : :bid
        end

        def operation
          if @data[:operation] == 0
            :insert
          else
            @data[:operation] == 1 ? :update : :delete
          end
        end

        def to_human
          "<#{message_type}: #{operation} #{side} @ " +
            "#{position} = #{price} x #{size}>"
        end
      end

      MarketDepthL2 =
        def_message 13, MarketDepth, # Fields descriptions - see above
                    %i[request_id int],
                    %i[position int],
                    %i[market_maker string], # The exchange hosting this order.
                    %i[operation int],
                    %i[side int],
                    %i[price decimal],
                    %i[size int]
    end # module Incoming
  end # module Messages
end # module IB
