module IB

    module  Strangle
      
      extend SpreadPrototype
      class << self


#  Fabricate a Strangle from a Master-Option
#  -----------------------------------------
#  If one Leg is known, the other is build by flipping the right and adjusting the strike by distance
#
#   Call with
#   IB::Strangle.fabricate an_option, numeric_value
			def fabricate master, distance

				flip_right = ->(the_right){  the_right == :put ? :call : :put   }

				error "Argument must be an option" unless [:option, :futures_option].include? master.sec_type


				initialize_spread( master ) do | the_spread |
					the_spread.add_leg master
					the_spread.add_leg( master
														 .essential
														 .merge( right: flip_right[master.right],
																		 strike: master.strike.to_f + distance.to_f ,
																	   local_symbol: '',
																	   con_id: 0 ) )
					error "Initialisation of Legs failed" if the_spread.legs.size != 2
					the_spread.description =  the_description( the_spread )
				end
			end


#  Build  Strangle out of an Underlying
#  -----------------------------------------
#  Needed attributes: :strike, :expiry
#
#  Optional: :trading_class, :multiplier
#
#   Call with
#   IB::Strangle.build from: IB::Contract, p:  a_value,  c:  a_value, expiry: yyyymm(dd)
			def build from:, **fields
				underlying = if from.is_a?  IB::Option
											 fields[:p] = from.strike unless fields.key?(:p) || from.right == :call
											 fields[:c] = from.strike unless fields.key?(:c) || from.right == :puta
											 fields[:expiry] = from.expiry unless fields.key?(:expiry)
											 fields[:trading_class] = from.trading_class unless fields.key?(:trading_class) || from.trading_class.empty?
											 fields[:multiplier] = from.multiplier unless fields.key?(:multiplier) || from.multiplier.to_i.zero?

											 details =  from.verify.first.contract_detail
											 IB::Contract.new( con_id: details.under_con_id,
																				currency: from.currency,
																			  exchange: from.exchange)
																			 .verify.first
																			 .essential
										 else
											 from
										 end
				kind = { :p => fields.delete(:p), :c => fields.delete(:c) }
				initialize_spread( underlying ) do | the_spread |
          leg_prototype  = IB::Option.new from.attributes
            .slice( :currency, :symbol, :exchange)
            .merge(defaults)
            .merge( fields )

          leg_prototype.sec_type = 'FOP' if underlying.is_a?(IB::Future)
          the_spread.add_leg leg_prototype.merge( right: :put, strike: kind[:p] ).verify.first
          the_spread.add_leg leg_prototype.merge( right: :call, strike: kind[:c] ).verify.first
					error "Initialisation of Legs failed" if the_spread.legs.size != 2
					the_spread.description =  the_description( the_spread )
				end
			end

      def defaults
      super.merge expiry: IB::Future.next_expiry
      end


      def requirements
				super.merge p: "the strike of the put option",
										c: "the strike of the call option",
									  expiry: "Expiry expressed as »yyyymm(dd)« (String or Integer) )"
      end



			def the_description spread
        "<Strangle #{spread.symbol}(#{spread.legs.map(&:strike).join(",")})[#{Date.parse(spread.legs.first.last_trading_day).strftime("%b %Y")}]>"
			end

      end # class
    end	# module combo
end  # module ib
