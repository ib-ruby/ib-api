require 'extensions/verify'
require 'extensions/market-price'
module IB

  class Contract
# returns the Option Chain of the contract (if available)
#
## parameters
### right:: :call, :put, :straddle
### ref_price::  :request or a numeric value
### sort:: :strike, :expiry 
### exchange:: List of Exchanges to be queried (Blank for all avaialable Exchanges)
		def option_chain ref_price: :request, right: :put, sort: :strike, exchange: ''

			ib =  Connection.current

			## Enable Cashing of Definition-Matrix
			@option_chain_definition ||= [] 

			my_req = nil; finalize= false
			
			# -----------------------------------------------------------------------------------------------------
			# get OptionChainDefinition from IB ( instantiate cashed Hash )
			if @option_chain_definition.blank?
				sub_sdop = ib.subscribe( :SecurityDefinitionOptionParameterEnd ) { |msg| finalize = true if msg.request_id == my_req }
				sub_ocd =  ib.subscribe( :OptionChainDefinition ) do | msg |
					if msg.request_id == my_req
						message =  msg.data
						# transfer the the first record to @option_chain_definition
						if @option_chain_definition.blank?
							@option_chain_definition =  msg.data

						end
							# override @option_chain_definition if a decent combintion of attributes is met
							# us- options:  use the smart dataset
							# other options: prefer options of the default trading class 
							if message[:currency] == 'USD' && message[:exchange] == 'SMART'	 || message[:trading_class] == symbol 
								@option_chain_definition =  msg.data

								finalize = true
							end
						end
					end
					
					verify do | c |
						my_req = ib.send_message :RequestOptionChainDefinition, con_id: c.con_id,
																			symbol: c.symbol,
																			exchange: sec_type == :future ? c.exchange : "", # BOX,CBOE',
																			sec_type: c[:sec_type]
					end

					Thread.new do  

			Timeout::timeout(1, IB::TransmissionError,"OptionChainDefinition not recieved" ) do
						loop{ sleep 0.1; break if finalize } 
			end
						ib.unsubscribe sub_sdop , sub_ocd
					end.join
				else
					Connection.logger.error { "#{to_human} : using cached data" }
				end

			# -----------------------------------------------------------------------------------------------------
			# select values and assign to options
			#
			unless @option_chain_definition.blank? 
				requested_strikes =  if block_given?
															 ref_price = market_price if ref_price == :request
															 if ref_price.nil?
																 ref_price =	 @option_chain_definition[:strikes].min  +
																	 ( @option_chain_definition[:strikes].max -  
																		@option_chain_definition[:strikes].min ) / 2 
																 Connection.logger.error{  "#{to_human} :: market price not set – using midpoint of avaiable strikes instead: #{ref_price.to_f}" }
															 end
															 atm_strike = @option_chain_definition[:strikes].min_by { |x| (x - ref_price).abs }
															 the_grouped_strikes = @option_chain_definition[:strikes].group_by{|e| e <=> atm_strike}	
															 begin
																 the_strikes =		yield the_grouped_strikes
#																 puts "TheStrikes #{the_strikes}"
																 the_strikes.unshift atm_strike unless the_strikes.first == atm_strike	  # the first item is the atm-strike
																 the_strikes
															 rescue
																 Connection.logger.error "#{to_human} :: not enough strikes :#{@option_chain_definition[:strikes].map(&:to_f).join(',')} "
																 []
															 end
														 else
															 @option_chain_definition[:strikes]
														 end

				# third friday of a month
				monthly_expirations =  @option_chain_definition[:expirations].find_all{|y| (15..21).include? y.day }
#				puts @option_chain_definition.inspect
				option_prototype = -> ( ltd, strike ) do 
						IB::Option.new( symbol: symbol, 
													 exchange: @option_chain_definition[:exchange],
													 trading_class: @option_chain_definition[:trading_class],
													 multiplier: @option_chain_definition[:multiplier],
													 currency: currency,  
													 last_trading_day: ltd, 
													 strike: strike, 
													 right: right )
				end
				options_by_expiry = -> ( schema ) do
					# Array: [ mmyy -> Options] prepares for the correct conversion to a Hash
					Hash[  monthly_expirations.map do | l_t_d |
						[  l_t_d.strftime('%m%y').to_i , schema.map{ | strike | option_prototype[ l_t_d, strike ]}.compact ]
					end  ]                         # by Hash[ ]
				end
				options_by_strike = -> ( schema ) do
					Hash[ schema.map do | strike |
						[  strike ,   monthly_expirations.map{ | l_t_d | option_prototype[ l_t_d, strike ]}.compact ]
					end  ]                         # by Hash[ ]
				end

				if sort == :strike
					options_by_strike[ requested_strikes ] 
				else 
					options_by_expiry[ requested_strikes ] 
				end
			else
				Connection.logger.error "#{to_human} ::No Options available"
				nil # return_value
			end
		end  # def

		# return a set of AtTheMoneyOptions
		def atm_options ref_price: :request, right: :put
			option_chain(  right: right, ref_price: ref_price, sort: :expiry) do | chain |
								chain[0]
			end

				
			end

		# return   InTheMoneyOptions
		def itm_options count:  5, right: :put, ref_price: :request, sort: :strike
			option_chain(  right: right,  ref_price: ref_price, sort: sort ) do | chain |
					if right == :put
						above_market_price_strikes = chain[1][0..count-1]
					else
						below_market_price_strikes = chain[-1][-count..-1].reverse
				end # branch
			end
		end		# def

    # return OutOfTheMoneyOptions
		def otm_options count:  5,  right: :put, ref_price: :request, sort: :strike
			option_chain( right: right, ref_price: ref_price, sort: sort ) do | chain |
					if right == :put
						#			puts "Chain: #{chain}"
						below_market_price_strikes = chain[-1][-count..-1].reverse
					else
						above_market_price_strikes = chain[1][0..count-1]
					end
			end
		end

	end  # class 
end   # module
