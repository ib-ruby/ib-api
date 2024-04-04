module IB




	class OrderCondition
		using IB::Support   # refine Array-method for decoding of IB-Messages
		# subclasses representing specialized condition types.

		Subclasses = Hash.new(OrderCondition)
		Subclasses[1] = IB::PriceCondition
		Subclasses[3] = IB::TimeCondition
		Subclasses[5] = IB::ExecutionCondition
		Subclasses[4] = IB::MarginCondition
		Subclasses[6] = IB::VolumeCondition
		Subclasses[7] = IB::PercentChangeCondition


		# This builds an appropriate subclass based on its type
		#
		def self.make_from  buffer
			condition_type = buffer.read_int
			OrderCondition::Subclasses[condition_type].make( buffer )
		end
	end  # class
end # module
