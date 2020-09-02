# These modules are used to facilitate referencing of most common Ordertypes

module IB
	module OrderPrototype




		def order **fields

			# special treatment of size:  positive numbers --> buy order, negative: sell 
			if fields[:size].present? && fields[:action].blank?
				error "Size = 0 is not possible" if fields[:size].zero?
				fields[:action] = fields[:size] >0 ? :buy  : :sell
				fields[:size] = fields[:size].abs
			end
			# change aliases  to the original. We are modifying the fields-hash.
			fields.keys.each{|x| fields[aliases.key(x)] = fields.delete(x) if aliases.has_value?(x)}
			# inlcude defaults (arguments override defaults)
			the_arguments = defaults.merge fields
			# check if requirements are fullfilled
			necessary = requirements.keys.detect{|y| the_arguments[y].nil?}
			if necessary.present?
				msg =self.name + ".order -> A necessary field is missing: #{necessary}: --> #{requirements[necessary]}"
				error msg, :args, nil
			end
			if alternative_parameters.present?
				unless ( alternative_parameters.keys  & the_arguments.keys ).size == 1
					msg =self.name + ".order -> One of the alternative fields needs to be specified: \n\t:" +
						"#{alternative_parameters.map{|x| x.join ' => '}.join(" or \n\t:")}"
					error msg, :args, nil
				end
			end

			# initialise order with given attributes	
			IB::Order.new the_arguments
		end

		def alternative_parameters
			{}
		end
		def requirements
			{ action: IB::VALUES[:side], total_quantity: 'also aliased as :size' }
		end

		def defaults
			{  tif: :good_till_cancelled }
		end

		def optional
			{ account: 'Account(number) to trade on' }
		end

		def aliases
			{  total_quantity: :size }
		end

		def parameters
			the_output = ->(var){ var.map{|x| x.join(" --> ") }.join("\n\t: ")}

			"Required : " + the_output[requirements] + "\n --------------- \n" +
				"Optional : " + the_output[optional] + "\n --------------- \n" 

		end

	end
end
