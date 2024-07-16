require 'order_helper'

RSpec.shared_examples 'a valid NQ-FUT Combo' do

    its( :exchange ) { should eq 'CME' }
    its( :symbol )   { should eq "NQ" }
#   its( :market_price )   { should be_a Numeric }
end

RSpec.shared_examples 'serialize two Combo-legs' do

    it "the con_id's are serialized" do
      con_ids =  subject.contract.combo_legs.map &:con_id
      buy_and_sell =  subject.contract.combo_legs.map{|y| y.action.to_s.upcase}
      exchanges =  subject.contract.combo_legs.map &:exchange
      expect( subject.serialize_combo_legs.size ).to eq 5
      expect( subject.serialize_combo_legs.flatten.slice(1,8 )).to eq [ con_ids[0],
                                                                        1,                # quantity
                                                                        buy_and_sell[0],
                                                                        exchanges[0],0,0,"",-1 ]
      expect( subject.serialize_combo_legs.flatten.slice(9,8 )).to eq [ con_ids[1],
                                                                        1,                # quantity
                                                                        buy_and_sell[1],
                                                                        exchanges[1],0,0,"",-1 ]

#      expect( subject.serialize_combo_legs[1..2].map{|y| y.at 2} ).to eq con_ids
    end
end

RSpec.describe "IB::Spread" do
  let( :the_option ) { IB::Symbols::Options.stoxx.merge( strike: 5000 ) }
  let( :the_spread ) { IB::Calendar.fabricate IB::Symbols::Futures.nq, '3m' }

  before(:all) do
    establish_connection
    ib = IB::Connection.current
    ib.subscribe( :Alert ){|y| puts y.to_human }
    ib.activate_plugin 'verify'
    ib.activate_plugin 'spread-prototypes'
    ib.activate_plugin 'order-prototypes'
    ib.activate_plugin 'symbols'
    ib.activate_plugin 'market-price'
  end

  after(:all) do
    close_connection
  end


  context "initialize by fabrication" do

    subject{ the_spread }
    it{ is_expected.to be_a IB::Bag }
    it_behaves_like 'a valid NQ-FUT Combo'

    it "has proper combo-legs" do
      expect( subject.combo_legs.first.side ).to eq  :buy
      expect( subject.combo_legs.last.side ).to eq :sell
    end
  end

  context "serialize the spread in the order process" do
    subject { IB::Limit.order contract: the_spread, size: 1, price: 45 }

        it_behaves_like "serialize limit order fields"
        it_behaves_like "serialize two Combo-legs"
        it { expect( subject.serialize_combo_legs ).to eq [ the_spread.serialize_legs,
                                                           0 ,[], 0 , [] ] }
                                                   # leg-prices  + combo-params



  end

  context "leg management"   do
    subject { the_spread }

    its( :legs ){ is_expected.to have(2).elements }

    it "add a leg" do
    expect{ subject.add_leg( the_option  )  }.to  change{ subject.legs.size }.by(1)
    end

    it "remove a leg" do
    # non existing leg
    expect{ subject.remove_leg( the_option  )  }.not_to  change{ subject.legs.size }

#   subject.add_leg( the_option  ) 
    expect{ subject.remove_leg( 0 )  }.to  change{ subject.legs.size }.by(-1)
    end
  end

end
