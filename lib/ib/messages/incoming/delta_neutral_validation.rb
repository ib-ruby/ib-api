module IB
  module Messages
    module Incoming
      # The server sends this message upon accepting a Delta-Neutral DN RFQ
      # - see API Reference p. 26
      DeltaNeutralValidation = def_message 56,
                                           %i[request_id int],
                                           %i[underlying con_id int],
                                           %i[underlying delta decimal],
                                           %i[underlying price decimal]
      class DeltaNeutralValidation
        def underlying
          @underlying = IB::Underlying.new @data[:underlying]
        end

        alias under_comp underlying
      end # DeltaNeutralValidation
    end # module Incoming
  end # module Messages
end # module IB
