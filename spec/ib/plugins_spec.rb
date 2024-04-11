require "main_helper"

describe "Connect to Gateway or TWS"  do
	before(:all){ establish_connection }

  after(:all) { close_connection }

	context "A new connection" do
		it{ expect( IB::Connection.current ).to be_a IB::Connection }
	end

  context "Plugin not present" do
    Given( :current ){ IB::Connection.current }
    Then { current.plugins == [] }
    Then { expect{ current.activate_plugin('invalid') }.to raise_error IB::Error }

  end

  context "Verify Plugin" do
    let( :stock ) { IB::Stock.new symbol: 'M' }

    it  "Prior to the activation of the verify plugin"  do
      expect{ stock.verify }.to raise_error NoMethodError
    end

    it " Activated Verify Plugin " do

    current =  IB::Connection.current
    status = current.activate_plugin('verify')
    expect( status ).to be_truthy

    verified_stocks =  stock.verify
    expect( verified_stocks).to be_a  Array
    complete_stock = verified_stocks.first
    expect( complete_stock.con_id).to be > 0
    end
  end




  end


