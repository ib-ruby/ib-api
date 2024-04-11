module IB
    module  Straddle
      extend SpreadPrototype
      class << self


#  Fabricate a Straddle from a Master-Option
#  -----------------------------------------
#  If one Leg is known, the other is simply build by flipping the right
#
#   Call with
#   IB::Spread::Straddle.fabricate an_option
			def fabricate master

				flip_right = ->(the_right){  the_right == :put ? :call : :put   }
				error "Argument must be a IB::Option" unless [ :option, :futures_option ].include?( master.sec_type )

				initialize_spread( master ) do | the_spread |
					the_spread.add_leg master.essential
					the_spread.add_leg( master.essential.merge( right: flip_right[master.right], local_symbol: "") )
					error "Initialisation of Legs failed" if the_spread.legs.size != 2
					the_spread.description =  the_description( the_spread )
				end
			end

#  Build  Straddle out of an Underlying
#  -----------------------------------------
#  Needed attributes: :strike, :expiry
#
#  Optional: :trading_class, :multiplier
#
#   Call with
#   IB::Spread::Straddle.build from: IB::Contract, strike: a_value, expiry: yyyymmm(dd)
			def build from:, ** fields
				if  from.is_a?  IB::Option
					fabricate from.merge(fields)
				else
					initialize_spread( from ) do | the_spread |
						leg_prototype  = IB::Option.new from.attributes
						.slice( :currency, :symbol, :exchange)
						.merge(defaults)
            .merge( fields )

						leg_prototype.sec_type = 'FOP' if from.is_a?( IB::Future )
            the_spread.add_leg leg_prototype.merge( right: :put ).verify.first
            the_spread.add_leg leg_prototype.merge( right: :call ).verify.first
						error "Initialisation of Legs failed" if the_spread.legs.size != 2
						the_spread.description =  the_description( the_spread )
					end
				end
			end

      def defaults
        super.merge expiry: IB::Future.next_expiry
      end

      def requirements
				super.merge strike: "the strike of both options",
									  expiry: "Expiry expressed as »yyyymm(dd)« (String or Integer)"
      end

			def the_description spread
			 "<Straddle #{spread.symbol}(#{spread.legs.first.strike})[#{Date.parse(spread.legs.first.last_trading_day).strftime("%b %Y")}]>"
			end

      end # class
    end	# module combo
end  # module ib
