module IB
  module Messages
    module Incoming
      extend Messages # def_message macros

      TickGeneric = def_message [45, 6], AbstractTick,
                                [:ticker_id, :int],
                                [:tick_type, :int],
                                [:value, :float]
    end
  end
end
