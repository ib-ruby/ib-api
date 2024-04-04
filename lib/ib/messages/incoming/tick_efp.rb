module IB
  module Messages
    module Incoming
      extend Messages # def_message macros


      TickEFP = def_message [47, 6], AbstractTick,
                            [:ticker_id, :int],
                            [:tick_type, :int],
                            [:basis_points, :decimal],
                            [:formatted_basis_points, :string],
                            [:implied_futures_price, :decimal],
                            [:hold_days, :int],
                            [:dividend_impact, :decimal],
                            [:dividends_to_expiry, :decimal]
    end
  end
end
