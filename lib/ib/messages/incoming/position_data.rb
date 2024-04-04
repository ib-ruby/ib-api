module IB
  module Messages
    module Incoming

			PositionData =
				def_message( [61,3] , ContractMessage,
					[:account, :string],
          [:contract, :contract], # read standard-contract 
#																	 [ con_id, symbol,. sec_type, expiry, strike, right, multiplier,
																	 # primary_exchange, currency, local_symbol, trading_class ] 
          [:position, :decimal],   # changed from int after Server Vers. MIN_SERVER_VER_FRACTIONAL_POSITIONS
					[:price, :decimal]
									 ) do 
#        def to_human
          "<PositionValue: #{account} ->  #{contract.to_human} ( Amount #{position}) : Market-Price #{price} >"
        end


    end # module Incoming
  end # module Messages
end # module IB
