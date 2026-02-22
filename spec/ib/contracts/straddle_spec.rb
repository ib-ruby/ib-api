require 'combo_helper'
STRIKE_ESTX =  4800   # fill in an appropiate strike for EuroStoxx 
STRIKE_ES = 5800      # same for ES-Future
STRIKE_WFC =  70      # same for Wells Fargo
RSpec.describe "IB::Straddle" do
  let ( :the_option ){ IB::Option.new  symbol: :Estx50, right: :put, strike: STRIKE_ESTX, expiry: IB::Option.next_expiry }
  let ( :the_bag ){ IB::Symbols::Combo::stoxx_straddle }
  before(:all) do
    establish_connection :gateway
    IB::Connection.current.activate_plugin 'spread-prototypes'
    IB::Connection.current.activate_plugin 'order-prototypes'
    IB::Connection.current.activate_plugin 'symbols'
    IB::Connection.current.activate_plugin 'market-price'
    IB::Connection.current.subscribe( :Alert ){|y|  puts y.to_human } 
  end

  after(:all) do
    close_connection
  end


  context "fabricate with master-option" do
    subject { IB::Straddle.fabricate IB::Symbols::Options.stoxx.merge( strike: STRIKE_ESTX ) }
    it{ is_expected.to be_a IB::Bag }
    it_behaves_like 'a valid Estx Combo'
    
      
  end

  context "build with index underlying" do
    subject{ IB::Straddle.build from: IB::Symbols::Index.stoxx, strike: STRIKE_ESTX , expiry: IB::Option.next_expiry , trading_class: 'OESX' }

    it{ is_expected.to be_a IB::Spread  }
    it_behaves_like 'a valid Estx Combo'
  end

  context "build with future underlying"  do
    subject{ IB::Straddle.build from: IB::Symbols::Futures.es, strike: STRIKE_ES   }

    it{ is_expected.to be_a IB::Spread  }
    it_behaves_like 'a valid ES-FUT Combo'
  end

  context "fabricate with stock underlying" do
    subject{ IB::Straddle.fabricate IB::Symbols::Options.aapl  }

    it{ is_expected.to be_a IB::Spread  }
    it_behaves_like 'a valid apple-stock Combo'
  end

  context "build with option"  do
    subject{ IB::Straddle.build from: the_option, strike: STRIKE_ESTX }

    it{ is_expected.to be_a IB::Spread }
    it_behaves_like 'a valid Estx Combo'
  end
end
