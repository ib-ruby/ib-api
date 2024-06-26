require 'combo_helper'

RSpec.describe "IB::Calendar" do
  before(:all) do
    establish_connection :gateway
    IB::Connection.current.activate_plugin 'spread-prototypes'
    IB::Connection.current.activate_plugin 'order-prototypes'
    IB::Connection.current.activate_plugin 'symbols'
    IB::Connection.current.activate_plugin 'roll'
    IB::Connection.current.activate_plugin 'market-price'
    IB::Connection.current.subscribe( :Alert ){|y|  puts y.to_human }
  end

  after(:all) do
    close_connection
  end

  let ( :the_option ){ IB::Symbols::Options.stoxx.merge strike: 4800, right: :call, trading_class: 'OESX' }

	context "initialize with master-option and second expiry" do
    subject { IB::Calendar.fabricate the_option,  IB::Option.next_expiry( Date.today + 30 ) }
    it{ puts subject.as_table }
		it{ is_expected.to be_a IB::Bag }
		it_behaves_like 'a valid Estx Combo'
	end

	context "initialize with underlying, strike and distance of the two legs"  do
		subject{ IB::Calendar.build( from: IB::Symbols::Index.stoxx,
																 strike: 4900,
																 right: :put,
																 trading_class: 'OESX',
																 front:  IB::Option.next_expiry ,
																 back:  '-1m'
															 ) }

    it{ puts subject.as_table }
		it{ is_expected.to be_a IB::Spread }
		it_behaves_like 'a valid Estx Combo'
	end
	context "initialize with Future-contract and distance" do
    subject{ IB::Calendar.fabricate  IB::Symbols::Futures.zn.next_expiry, '3m' }

    it{ puts subject.as_table }
		it{ is_expected.to be_a IB::Spread }
		it_behaves_like 'a valid ZN-FUT Combo'
	end
end
