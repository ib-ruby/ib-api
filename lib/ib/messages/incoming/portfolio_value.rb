module IB
  module Messages
    module Incoming
      class ContractMessage < AbstractMessage
        def contract
          @contract = IB::Contract.build @data[:contract]
        end
      end

      PortfolioValue = def_message [7, 8], ContractMessage,
                                   %i[contract contract], # read standard-contract
                                   %i[portfolio_value position decimal],
                                   %i[portfolio_value market_price decimal],
                                   %i[portfolio_value market_value decimal],
                                   %i[portfolio_value average_cost decimal],
                                   %i[portfolio_value unrealized_pnl decimal], # May be nil!
                                   %i[portfolio_value realized_pnl decimal], #   May be nil!
                                   %i[account string]

      class PortfolioValue
        def to_human
          #	"<PortfolioValue: #{contract.to_human} #{portfolio_value}>"
          portfolio_value.to_human
        end

        def portfolio_value
          unless @portfolio_value.present?
            @portfolio_value = IB::PortfolioValue.new @data[:portfolio_value]
            @portfolio_value.contract = contract
            @portfolio_value.account =  account
          end
          @portfolio_value # return_value
        end

        def account_name
          @account_name =  @data[:account]
        end

        #					alias :to_human :portfolio_value
      end # PortfolioValue

      PositionData =
        def_message([61, 3], ContractMessage,
                    %i[account string],
                    %i[contract contract], # read standard-contract
                    #																	 [ con_id, symbol,. sec_type, expiry, strike, right, multiplier,
                    # primary_exchange, currency, local_symbol, trading_class ]
                    %i[position decimal], # changed from int after Server Vers. MIN_SERVER_VER_FRACTIONAL_POSITIONS
                    %i[price decimal]) do
          #        def to_human
          "<PositionValue: #{account} ->  #{contract.to_human} ( Amount #{position}) : Market-Price #{price} >"
        end

      PositionDataEnd = def_message(62)
      PositionsMulti =  def_message(71, ContractMessage,
                                    %i[request_id int],
                                    %i[account string],
                                    %i[contract contract], # read standard-contract
                                    %i[position decimal], # changed from int after Server Vers. MIN_SERVER_VER_FRACTIONAL_POSITIONS
                                    %i[average_cost decimal],
                                    %i[model_code string])

      PositionsMultiEnd = def_message 72
    end # module Incoming
  end # module Messages
end # module IB
