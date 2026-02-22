module IB
  module Messages
    module Incoming


      PortfolioValue = def_message [7, 8], ContractMessage,
            [:contract, :contract], # read standard-contract
            [:portfolio_value, :position, :decimal],
            [:portfolio_value,:market_price, :decimal],
            [:portfolio_value,:market_value, :decimal],
            [:portfolio_value,:average_cost, :decimal],
            [:portfolio_value,:unrealized_pnl, :decimal], # May be nil!
            [:portfolio_value,:realized_pnl, :decimal], #   May be nil!
            [:account, :string]


        class PortfolioValue


          def to_human
        # "<PortfolioValue: #{contract.to_human} #{portfolio_value}>"
            portfolio_value.to_human
          end
          def portfolio_value
            unless @portfolio_value.present?
              @portfolio_value =  IB::PortfolioValue.new   @data[:portfolio_value]
              @portfolio_value.contract = contract
              @portfolio_value.account =  account
            end
            @portfolio_value # return_value
          end

          def account_name
            @account_name =  @data[:account]
          end

#         alias :to_human :portfolio_value
        end # PortfolioValue






    end # module Incoming
  end # module Messages
end # module IB
