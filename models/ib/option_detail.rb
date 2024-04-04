module IB

  # Additional Option properties and Option-Calculations
  class OptionDetail < IB::Base
    include BaseProperties

    prop :delta,  :gamma, :vega, :theta, # greeks
         :implied_volatility,
	 :pv_dividend, # anticipated Dividend
	 :under_price,  # price of the Underlying
	 :option_price,
	 :close_price,
	 :open_tick,
	 :bid_price,
	 :ask_price,
	 :prev_strike,
	 :next_strike,
	 :prev_expiry,
	 :next_expiry,
	 :option_price,
	 :updated_at
    belongs_to :option

    # returns true if all datafields are filled with reasonal data
    def complete?
     fields= [ :delta,  :gamma, :vega, :theta,
         :implied_volatility, :pv_dividend, :open_tick,
	 :under_price, :option_price, :close_price, :bid_price, :ask_price]

      !fields.detect{|y| self.send(y).nil?}

    end

    def greeks?
     fields= [ :delta,  :gamma, :vega, :theta,
         :implied_volatility]

      !fields.detect{|y| self.send(y).nil?}

    end

		def prices?
			fields = [:implied_volatility, :under_price, :option_price]
      !fields.detect{|y| self.send(y).nil?}
		end

		def iv
			implied_volatility
		end

		def spread
			bid_price - ask_price
		end 

    def to_human
      outstr= ->( item ) { if item.nil? then "--" else  sprintf("%g" , item)  end  }
      att = " optionPrice: #{ outstr[ option_price ]}, UnderlyingPrice: #{ outstr[ under_price] } impl.Vola: #{ outstr[ implied_volatility ]} ; dividend: #{ outstr[ pv_dividend ]}; "
      greeks = "Greeks::  delta:  #{ outstr[ delta ] }; gamma: #{ outstr[ gamma ]}, vega: #{ outstr[ vega ] }; theta: #{ outstr[ theta ]}" 
      prices= " close: #{ outstr[ close_price ]}; bid: #{ outstr[ bid_price ]}; ask: #{ outstr[ ask_price ]} "
      if	complete?
				"< "+ prices + "\n" + att + "\n" + greeks + " >"
			elsif prices?
				"< " + att + greeks + " >"
      else
	"< " + greeks + " >"
      end

    end

    def table_header
      [ 'Greeks', 'price',  'impl. vola', 'dividend', 'delta','gamma', 'vega' , 'theta']
    end
 
    def table_row
      outstr= ->( item ) { { value: item.nil? ? "--" : sprintf("%g" , item) , alignment: :right } } 
      outprice= ->( item ) { { value: item.nil? ? "--" : sprintf("%7.2f" , item) , alignment: :right } } 
      option_short = ->{"#{option.right}  #{option.symbol}#{ "/"+ option.trading_class unless option.trading_class == option.symbol } #{option.expiry}  #{option.strike}"}
      [ option_short[], outprice[ option_price ], outprice[ implied_volatility ],
        outprice[ pv_dividend ], 
        outprice[ delta ], outprice[ gamma ], outprice[ vega ] , outprice[ theta ] ]
    end

  end  # class
end # module
