require "main_helper"

describe "Connect to Gateway or TWS"  do
	before(:all){ establish_connection 'managed-accounts'}

  after(:all) { close_connection }


  context "Active Connection" do
    Given( :current ){ IB::Connection.current }
    Then { current.is_a? IB::Connection }
    Then { current.plugins.include?  'managed-accounts' }

    context "Plugin works as expected" do
      Given( :clients ){ current.clients }
      Then { clients.is_a? Array }
      Then { clients.size >= 1 }
      Given( :advisor ){ current.advisor }
      Then { advisor.is_a? IB::Account }
      Then { advisor.account =~ /F/ }
      Given( :client ){ clients.first }
      Then { client.is_a? IB::Account }
      Then { client.account =~ /U/ }
      Then { client.portfolio_values.is_a? Array }
      Then { client.contracts.is_a? Array }
      Then { client.account_values.is_a? Array }
      When( :all_contracts ){ client.contracts }
      Then { all_contracts.map{ |c| c.is_a? IB::Contract }.uniq == [true] }
      When( :all_portfolio_positions ){ client.portfolio_values }
      Then { all_portfolio_positions.map{ |p| p.is_a? IB::PortfolioValue }.uniq == [true] }

    end
  end
end


