# require 'ib/verify'
module IB
  class Spread  < Bag
		has_many :legs

		using IBSupport

=begin
Parameters:   front: YYYMM(DD)
							back: {n}w, {n}d or YYYYMM(DD)

Adds (or substracts) relative (back) measures to the front month, just passes absolute YYYYMM(DD) value
	
	front: 201809   back:  2m (-1m) --> 201811 (201808)
	front: 20180908 back:  1w (-1w) --> 20180918 (20180902)
=end

		def transform_distance front, back
			# Check Format of back: 201809 --> > 200.000
			#	                      20180989 ---> 20.000.000
			start_date = front.to_i < 20000000 ?  Date.strptime(front.to_s,"%Y%m") :  Date.strptime(front.to_s,"%Y%m%d") 
			nb = if back.to_i > 200000 
						 back.to_i
					 elsif back[-1] == "w" && front.to_i > 20000000
						 start_date + (back.to_i * 7)
					 elsif back[-1] == "m" && front.to_i > 200000
						 start_date >> back.to_i
					 else
						 error "Wrong date #{back} required format YYYMM, YYYYMMDD ord {n}w or {n}m"
					 end
			if nb.is_a?(Date)	
				if back[-1]=='w'
					nb.strftime("%Y%m%d")
				else
					nb.strftime("%Y%m")
				end
			else
				nb
			end 
		end # def 
	
		def to_human
			self.description
		end

		def calculate_spread_value( array_of_portfolio_values )
			array_of_portfolio_values.map{|x| x.send yield }.sum if block_given?
		end
	
		def fake_portfolio_position(  array_of_portfolio_values )
				calculate_spread_value= ->( a_o_p_v, attribute ) do
							a_o_p_v.map{|x| x.send attribute }.sum 
				end
				ar=array_of_portfolio_values
				IB::PortfolioValue.new  contract: self, 
					average_cost: 	calculate_spread_value[ar, :average_cost],
					market_price: 	calculate_spread_value[ar, :market_price],
					market_value: 	calculate_spread_value[ar, :market_value],
					unrealized_pnl: 	calculate_spread_value[ar, :unrealized_pnl],
					realized_pnl: 	calculate_spread_value[ar, :realized_pnl],
					position: 0

		end


		# adds a leg to any spread
		#
		# Parameter: 
		#		contract:  Will be verified. Contract.essential is added to legs-array
		#		action: :buy or :sell
		#		weight:
		#		ratio:
		#		
		#	Default:  action: :buy, 	weight: 1

		def add_leg contract,  **leg_params
			evaluated_contracts =  []
			nc =	contract.verify.first.essential
			#			weigth = 1 --> sets Combo.side to buy and overwrites the action statement
#			leg_params[:weight] = 1 unless leg_params.key?(:weight) || leg_params.key?(:ratio)
			if nc.is_a?( IB::Contract) && nc.con_id.present?
					the_leg= ComboLeg.new( nc.attributes.slice( :con_id, :exchange )
																					.merge( leg_params ))
					self.combo_legs << the_leg 
					self.description = "#{description.nil? ? "": description} added #{nc.to_human}" rescue "Spread: #{nc.to_human}"
					self.legs << nc
			end
			self  # return value to enable chaining


		end

		# removes the contract from the spread definition
		#
		def remove_leg contract
			contract.verify do |c|
				legs.delete_if { |x| x.con_id == c.con_id }
				combo_legs.delete_if { |x| x.con_id == c.con_id }
				self.description = description + " removed #{c.to_human}"
			end
			self
		end

# essentail
# effectivley clones the object
# 
		def essential
      the_es = self.class.new invariant_attributes
      the_es.legs = legs.map{|y| IB::Contract.build y.invariant_attributes}
      the_es.combo_legs = combo_legs.map{|y| IB::ComboLeg.new y.invariant_attributes }
      the_es.description = description
      the_es  # return
		end

		def  multiplier
			(legs.map(&:multiplier).sum/legs.size).to_i
		end
		
		# provide a negative con_id
		def con_id
			if attributes[:con_id].present? && attributes[] < 0
				attributes[:con_id]
			else
				-legs.map{ |x| x.is_a?(String) ? x.expand.con_id : x.con_id}.sum
			end
		end


		def non_guaranteed= x
      super.merge		combo_params: [ ['NonGuaranteed', x] ]
		end


		def non_guaranteed
     	combo_params['NonGuaranteed']
		end
#  optional: specify default order prarmeters for all spreads
#		def order_requirements
#		 super.merge		symbol: symbol
#		end


		def self.build_from_json container
			read_leg = ->(a) do 
				  IB::ComboLeg.new :con_id => a.read_int,
                           :ratio => a.read_int,
                           :action => a.read_string,
                           :exchange => a.read_string

			end
      object= self.new  container['Spread'].clone.read_contract
      object.legs = container['legs'].map{|x| IB::Contract.build x.clone.read_contract}
      object.combo_legs = container['combo_legs'].map{ |x| read_leg[ x.clone ] } 
      object.description = container['misc'].clone.read_string
			object

		end

	end


end
