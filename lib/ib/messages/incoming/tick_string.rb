module IB
  module Messages
    module Incoming
      extend Messages # def_message macros

      TickString = def_message [46, 6], AbstractTick,
                               [:ticker_id, :int],
                               [:tick_type, :int],
                               [:value, :string]
    end
  end
end

