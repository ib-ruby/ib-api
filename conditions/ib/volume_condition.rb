module IB




	class VolumeCondition < OrderCondition
		using IB::Support   # refine Array-method for decoding of IB-Messages
    include BaseProperties

		prop :volume

		def condition_type
		6
		end

		def self.make  buffer
			m = self.new  conjunction_connection:  buffer.read_string,
										operator: buffer.read_int,
										volumne: buffer.read_int

			the_contract = IB::Contract.new con_id: buffer.read_int, exchange: buffer.read_string
			m.contract = the_contract
			m
		end

		def serialize

			super << self[:operator] << volume <<  serialize_contract_by.con_id 
		end

		# dsl:   VolumeCondition.fabricate some_contract, ">=", 50000
		def self.fabricate contract, operator, volume
			error "Condition Operator has to be \">=\" or \"<=\" " unless ["<=", ">="].include? operator
			self.new	operator: operator,
								volume: volume,
								contract: verify_contract_if_necessary( contract )
		end
	end

end # module
