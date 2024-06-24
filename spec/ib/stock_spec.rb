require "main_helper"

describe  IB::Stock do
	before(:all) do
    establish_connection
    ib = IB::Connection.current
    ib.activate_plugin 'verify'
    ib.activate_plugin 'symbols'
  end

  after(:all) { close_connection }

  describe "Equility of Stock Contracts" do
    Given( :msft  ) { IB::Symbols::Stocks.msft }
    Then { msft.is_a? IB::Stock }
    describe "specify the symbol as symbol" do
      Given( :ms_stock ){ IB::Stock.new symbol: :msft }
      Then { ms_stock.is_a? IB::Stock }
      Then { ms_stock == msft }
    end

    describe "specify the symbil as string " do
      Given( :ms_stock ){ IB::Stock.new symbol: 'msft' }
      Then { ms_stock.is_a? IB::Stock }
      Then { ms_stock == msft }
    end
  end


  describe "Merging of Attributes" do

    Given( :msft  ) { IB::Symbols::Stocks.msft }
    When( :verified_microsoft ){ msft.verify.first }
    Then{ msft != verified_microsoft }
    Then{ verified_microsoft.con_id == 272093 }
    Then{ verified_microsoft.contract_detail.is_a? IB::ContractDetail }

    describe "merging of similar stocks  is possible" do
      Given( :ford ){ verified_microsoft.merge symbol: 'F' }
      Then{ ford.con_id.zero? }
      Then{ ford.contract_detail.nil? }
      When( :verified_ford ){ ford.verify.first }
      Then{ verified_ford.con_id ==  9599491}
    end

    describe "even merging of stocks from different countries is possible" do
      Given( :siemens_energy ){ verified_microsoft.merge symbol: :enr, currency: :eur  }
      Then{ siemens_energy.con_id.zero? }
      When( :verified_enr ){ siemens_energy.verify.first }
      #    Then{ expect { siemens_energy.verify }.to raise_error( IB::VerifyError ) }
      Then{ verified_enr.con_id == 447545380 }
    end

  end
end

