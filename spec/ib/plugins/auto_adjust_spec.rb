require "main_helper"

describe "Connect to TWS and activate Plugin"  do
	before(:all) do
    establish_connection
    c =  IB::Connection.current
    c.activate_plugin "verify"
    c.activate_plugin "order-prototypes"
    c.activate_plugin "auto-adjust"
  end

  after(:all) { close_connection }

	context "A new connection is established" do
		it{ expect( IB::Connection.current ).to be_a IB::Connection }
	end

  context "Read min_tick" do
    Given( :m_stock ) { IB::Stock.new( symbol: 'M' ).verify.first }
    When( :min_tick ){  m_stock.contract_detail.min_tick }
    Then { min_tick == 0.01  }
  end

  context "Working on an ordenary us-stock (2 digits) [contract is not verified]" do
    Given( :stock ) { IB::Stock.new( symbol: 'M' ) }
    context "Create an order with a suitable price" do
      Given( :order ) { IB::Limit.order price: 50.01, size: 100, action: :buy, contract: stock }
      When { order.auto_adjust }
      Then { order.limit_price == 50.01 }
    end
    context "Create an order which needs to be auto adjusted" do
      Given( :order1 ) { IB::Limit.order price: 50.024, size: 100, action: :buy, contract: stock }
      When { order1.auto_adjust }
      Then { order1.limit_price == 50.02 }
      Given( :order2 ) { IB::Limit.order price: 50.026, size: 100, action: :buy, contract: stock }
      When { order2.auto_adjust }
      Then { order2.limit_price == 50.03 }
    end
  end
  context "Working on an european-stock with  4 digits [contract is verified]" do
    Given( :base_stock ) { IB::Stock.new( symbol: 'TKA', currency: :eur ) }
    When( :stock ) { base_stock.verify.first }
    When( :min_tick ){  stock.contract_detail.min_tick }
    Then { min_tick == 0.0001  }
    context "Create an order with a suitable price" do
      Given( :order ) { IB::Limit.order price: 5.001, size: 100, action: :buy, contract: stock }
      When { order.auto_adjust }
      Then { order.limit_price == 5.001 }
    end
    context "Create an order which needs to be auto adjusted" do
      Given( :order1 ) { IB::Limit.order price: 5.0024, size: 100, action: :buy, contract: stock }
      When { order1.auto_adjust }
      Then { order1.limit_price == 5.002 }
      Given( :order2 ) { IB::Limit.order price: 5.0026, size: 100, action: :buy, contract: stock }
      When { order2.auto_adjust }
      Then { order2.limit_price == 5.003 }
    end
  end
end


