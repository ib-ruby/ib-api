require 'combo_helper'
require 'order_helper'

RSpec.describe "IB::Butterfly" do
	before(:all) do
		establish_connection
    ib =  IB::Connection.current
    ib.activate_plugin 'verify'
    ib.activate_plugin 'spread-prototypes'
    ib.activate_plugin 'order-prototypes'
    ib.activate_plugin 'symbols'
    ib.activate_plugin 'market-price'

		ib.subscribe( :Alert ){|y|  puts y.to_human }
	end

after(:all) do
	close_connection
end

	let ( :the_option ){ IB::Symbols::Options.stoxx.merge( strike: 5000 ) }
	let ( :the_bag ){ IB::Symbols::Combo::stoxx_butterfly }

context "initialize with master-option"  do
	subject { IB::Butterfly.fabricate(  the_option, back: the_option.strike - 50, front: the_option.strike + 50 )}
  it{ puts subject.as_table }
	it{ is_expected.to be_a IB::Spread }
	it_behaves_like 'a valid Estx Combo'


end

context "initialize with underlying" do
	subject { IB::Butterfly.build( from: IB::Symbols::Index.stoxx,
                              strike: 5000,
                               front: 4950,
                                back: 5050,
                       trading_class: 'OESX' ) }
  it{ puts subject.as_table }
	it{ is_expected.to be_a IB::Spread }
	it_behaves_like 'a valid Estx Combo'
  end

context "create a limit-order" do
  subject { IB::Limit.order contract: IB::Symbols::Combo.stoxx_butterfly, size: 1, price: 25 }
  it{ puts subject.as_table }
  it{ puts subject.contract.as_table }
	it_behaves_like 'serialize limit order fields'
end
end
