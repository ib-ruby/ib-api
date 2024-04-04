module IB
  module Messages
    module Incoming


			PositionsMulti =  def_message( 71, ContractMessage,
																		[ :request_id, :int ],
																		[ :account, :string ],
																		[:contract, :contract], # read standard-contract
          [ :position, :decimal],   # changed from int after Server Vers. MIN_SERVER_VER_FRACTIONAL_POSITIONS
					[ :average_cost, :decimal],
					[ :model_code, :string ])
    end # module Incoming
  end # module Messages
end # module IB
