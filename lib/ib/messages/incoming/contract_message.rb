module IB
  module Messages
    module Incoming

      # used by PortfolioValue
      class ContractMessage < AbstractMessage
        def contract
          @contract = IB::Contract.build @data[:contract]
        end
      end
      end # module Incoming
  end # module Messages
end # module IB
