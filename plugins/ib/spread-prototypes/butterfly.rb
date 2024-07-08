module IB

    module  Butterfly

      extend SpreadPrototype
			class << self

				#  Fabricate a Butterfly from Scratch
				#  -----------------------------------------
				#
				#
				#
				#   Call with
				#   IB::Butterfly.fabricate  IB::Option.new( symbol: :estx50, strike: 3000, expiry:'201901'),
				#														front: 2850, back: 3150
				#
				#   or
				#   IB::Butterfly.build  from: Symbols::Index.stoxx
				#                         strike: 3000
			  #												  expiry: '201901', front: 2850, back: 3150
				#
				#		where :strike defines the center of the Spread.
				def  fabricate master, front:, back:

					error "fabrication is based on a master option. Please specify as first argument" unless master.is_a?(IB::Option)
					strike = master.strike
					master.right = :put unless master.right == :call
					l= master.verify
					if l.empty?
						error "Invalid Parameters. No Contract found #{master.to_human}"
					elsif l.size > 1
						error "ambigous contract-specification: #{l.map(&:to_human).join(';')}"
						available_trading_classes = l.map( &:trading_class ).uniq
						if available_trading_classes.size >1
							error "Refine Specification with trading_class: #{available_trading_classes.join('; ')} "
						else
							error "Respecify expiry, verification reveals #{l.size} contracts  (only 1 is allowed)"
						end
					end

					initialize_spread( master ) do | the_spread |
						strikes = [front, master.strike, back]
						strikes.zip([1, -2, 1]).each do |strike, ratio|
							action = ratio >0 ?  :buy : :sell
              leg =  IB::Option.new( master.attributes.merge( strike: strike )).verify.first.essential
							the_spread.add_leg  leg,  action: action,  ratio: ratio.abs
						end
						the_spread.description =  the_description( the_spread )
						the_spread.symbol = master.symbol
					end
				end

				def  build from: , front:, back:,  **options
					underlying_attributes =  { expiry: IB::Future.next_expiry, right: :put }.merge( from.attributes.slice( :symbol, :currency, :exchange, :strike )).merge( options )
					fabricate  IB::Option.new( underlying_attributes), front: front, back: back
				end

				def the_description spread
			x= [ spread.combo_legs.map(&:weight) , spread.legs.map( &:strike )].transpose
			 "<Butterfly #{spread.symbol} #{spread.legs.first.right}(#{x.map{|w,strike| "#{w} :#{strike} "}.join( '|+|' )} )[#{Date.parse(spread.legs.first.last_trading_day).strftime("%b %Y")}]>"
				end

				def defaults
					super.merge expiry: IB::Future.next_expiry,
						          right: :put
				end


				def requirements
					super.merge back: "the strike of the lower bougth option",
											front: "the strike of the upper bougth option"

				end

			end # class
		end	# module
end  # module ib
