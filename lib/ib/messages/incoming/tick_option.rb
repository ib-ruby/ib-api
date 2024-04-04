module IB
  module Messages
    module Incoming
      extend Messages # def_message macros

      # This message is received when the market in an option or its underlier moves.
      # TWS option model volatilities, prices, and deltas, along with the present
      # value of dividends expected on that options underlier are received.
      # TickOption message contains following @data:
      #    :ticker_id - Id that was specified previously in the call to reqMktData()
      #    :tick_type - Specifies the type of option computation (see TICK_TYPES).
      #    :implied_volatility - The implied volatility calculated by the TWS option
      #                          modeler, using the specified :tick_type value.
      #    :delta - The option delta value.
      #    :option_price - The option price.
      #    :pv_dividend - The present value of dividends expected on the options underlier
      #    :gamma - The option gamma value.
      #    :vega - The option vega value.
      #    :theta - The option theta value.
      #    :under_price - The price of the underlying.
      TickOption = TickOptionComputation =
          def_message([21, 0], AbstractTick,
                      [:ticker_id, :int],
                      [:tick_type, :int],
                      [:tick_attribute, :int],
                      [:implied_volatility, :decimal_limit_1], # -1 and below
                      [:delta, :decimal_limit_2],					#      -2 and below
                      [:option_price, :decimal_limit_1],	#      -1   -"-
                      [:pv_dividend, :decimal_limit_1],		#      -1   -"-
                      [:gamma, :decimal_limit_2],					#      -2   -"-
                      [:vega, :decimal_limit_2],					#      -2   -"-
                      [:theta, :decimal_limit_2],					#      -2   -"-
                      [:under_price, :decimal_limit_1]) do

            "<TickOption #{type}   " + 
                "option @ #{"%8.3f" % (option_price || -1)}, IV: #{"%4.3f" % (implied_volatility || -1)}, " +
						    "delta: #{"%5.3f" % (delta || -1)}, " +
                "gamma: #{"%6.4f" % (gamma || -1)}, vega: #{ "%6.5f" % (vega || -1)}, " + 
								"theta: #{"%7.6f" % (theta || -1)}, pv_dividend: #{"%5.3f" % (pv_dividend || -1)}, " +
							  "underlying @ #{"% 8.3f" % (under_price || -1)} >"
          end

			 class TickOption		
				 def greeks
					 { delta: delta, gamma: gamma, vega: vega, theta: theta }
				 end

				 def iv
					 implied_volatility
				 end
			
				 
				 def greeks? 
					 greeks.values.any? &:present?
				 end

			 end
    end
  end
end
