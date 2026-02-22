module IB
  module Messages
    module Incoming
      MarketDepthL2 =
          def_message 13, MarketDepth, # Fields descriptions - see above
                      [:request_id, :int],
                      [:position, :int],
                      [:market_maker, :string], # The exchange hosting this order.
                      [:operation, :int],
                      [:side, :int],
                      [:price, :decimal],
                      [:size, :int]
    end # module Incoming
  end # module Messages
end # module IB
