require 'combo_helper'
RSpec.shared_examples 'spread_params' do
  
end

RSpec.describe "IB::StockSpread" do
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


  context "initialize without ratio"  do
    subject { IB::StockSpread.fabricate 'T','GE' }
    it{ is_expected.to be_a IB::Spread }
#   it_behaves_like 'a valid Estx Combo'
    
    its(:symbol){ is_expected.to eq "GE,T" }
    its( :legs ){ is_expected.to have(2).elements}
#    its( :market_price ){ is_expected.to be_a BigDecimal }
      
    it "can be printed as table" do
      puts subject.as_table
    end

  end

  context "initialize with ratio" do
    subject { IB::StockSpread.fabricate IB::Stock.new( symbol:'T' ), IB::Stock.new(symbol: 'GE'), ratio:[1,-3] }
    it{ is_expected.to be_a IB::Spread }
#   it_behaves_like 'a valid Estx Combo'
    it "can be printed as table" do
      puts subject.as_table
    end
    
    its( :symbol){ is_expected.to eq "GE,T" }
    its( :legs ){ is_expected.to have(2).elements}
    its( :market_price ){ is_expected.to be_a BigDecimal }

    it "the ratio is met " do
      ratio =  subject.combo_legs.map &:ratio
      sides =  subject.combo_legs.map &:side

      expect( ratio ).to eq [ 1, 3 ]
      expect( sides ).to eq [ :buy, :sell ]
    end
      
  end
  context "initialize with (reverse) ratio" do
    subject { IB::StockSpread.fabricate IB::Stock.new( symbol:'GE' ), IB::Stock.new(symbol: 'T'), ratio:[1, -3] }
    it{ is_expected.to be_a IB::Spread }
    
    its(:symbol){ is_expected.to eq "GE,T" }
    its( :legs ){ is_expected.to have(2).elements}
    its( :market_price ){ is_expected.to be_a BigDecimal }
      
  end

  context "initialize with more then two stocks" do 

    it "fabricate raises an error " do 

      expect { IB::StockSpread.fabricate 'GE','T', "A", ratio:[1, -3, 5] }.to raise_error IB::Error
    end
  end
    subject { IB::StockSpread.fabricate IB::Stock.new( symbol:'GE' ), IB::Stock.new(symbol: 'T'), ratio:[1, -3] }
end
