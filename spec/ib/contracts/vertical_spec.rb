require 'combo_helper'

RSpec.describe "IB::Vertical" do
  before(:all) do
    establish_connection :gateway
    IB::Connection.current.activate_plugin 'spread-prototypes'
    IB::Connection.current.activate_plugin 'order-prototypes'
    IB::Connection.current.activate_plugin 'symbols'
#    IB::Connection.current.activate_plugin 'roll'
#    IB::Connection.current.activate_plugin 'market-price'
    IB::Connection.current.subscribe( :Alert ){|y|  puts y.to_human }
  end

  after(:all) do
    close_connection
  end


  context "fabricate with master-option" do
    subject { IB::Vertical.fabricate IB::Symbols::Options.stoxx , sell: 4800}
    it{ is_expected.to be_a IB::Bag }
    it_behaves_like 'a valid Estx Combo'
    
      
  end

  context "build with underlying"  do
    subject{ IB::Vertical.build from: IB::Symbols::Index.stoxx, buy: 4800, sell: 5000, expiry: IB::Option.next_expiry  }

    it{ is_expected.to be_a IB::Spread }
    it_behaves_like 'a valid Estx Combo'
  end
  context "build with option" do 
    subject{ IB::Vertical.build from: IB::Symbols::Options.stoxx, buy: 4900 }

    it{ is_expected.to be_a IB::Spread }
    it_behaves_like 'a valid Estx Combo'
  end
  context "build with Future" do
    subject{ IB::Vertical.build from: IB::Symbols::Futures.es, buy: 5900, sell: 6100 }

    it{ is_expected.to be_a IB::Spread }
    it_behaves_like 'a valid ES-FUT Combo'

  end
      
  context "fabricated with FutureOption" do
    subject do
      fo = IB::Vertical.build( from: IB::Symbols::Futures.es, buy: 5900, sell: 6100).legs.first
      IB::Vertical.fabricate fo, sell: 6200
    end
    it{ is_expected.to be_a IB::Spread }
    it_behaves_like 'a valid ES-FUT Combo'

  end
end
