# These modules are used to facilitate referencing of most common Spreads

# Spreads are created in  two ways:
#
#	(1) IB::Spread::{prototype}.build  from: {underlying},
#																		 trading_class: (optional)
#																		 {other specific attributes}
#
#	(2) IB::Spread::{prototype}.fabcricate master: [one leg},
#																			{other specific attributes}
#
#	They return a freshly instantiated Spread-Object
#
module IB
	module SpreadPrototype


		def build from: , **fields
		end


		def initialize_spread ref_contract = nil, **attributes
			error "Initializing of Spread failed – contract is missing" unless ref_contract.is_a?(IB::Contract)
      # make sure that :exchange, :symbol and :currency are present
			the_contract =  ref_contract.merge( **attributes ).verify.first
			error "Underlying for Spread is not valid: #{ref_contract.to_human}" if the_contract.nil?
			the_spread= IB::Spread.new  the_contract.attributes.slice( :exchange, :symbol, :currency )
			error "Initializing of Spread failed – Underling is no Contract" if the_spread.nil?
			yield the_spread if block_given?  # yield outside mutex controlled verify-environment
			the_spread  # return_value
		end

		def requirements
			{}
		end

		def defaults
			{}
		end

		def optional
			{ }
		end

		def parameters
			the_output = ->(var){ var.empty? ? "none" : var.map{|x| x.join(" --> ") }.join("\n\t: ")}

			"Required : " + the_output[requirements] + "\n --------------- \n" +
				"Optional : " + the_output[optional] + "\n --------------- \n" 

		end
	end
    Connection.current.activate_plugin "verify"
  [:straddle, :strangle, :vertical, :calendar, :"stock-spread", :butterfly].each do | pt |
    Connection.current.activate_plugin "spread_prototypes/#{pt.to_s}"
  end
end

#require 'ib/spread_prototypes/straddle'
#require 'ib/spread_prototypes/strangle'
#require 'ib/spread_prototypes/vertical'
#require 'ib/spread_prototypes/calendar'
#require 'ib/spread_prototypes/stock-spread'
#require 'ib/spread_prototypes/butterfly'
