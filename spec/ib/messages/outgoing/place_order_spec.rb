require 'main_helper'

RSpec.describe IB::Messages::Outgoing  do


  context 'Newly instantiated Message' do

    subject do
      IB::Messages::Outgoing::PlaceOrder.new(
        local_id: 123,
        contract:  IB::Stock.new( symbol: 'F' ),
        order: IB::Order.new( total_quantity: 100, limit_price: 25, tif: :good_til_canceled ))
    end

    it { should be_an IB::Messages::Outgoing::PlaceOrder }
    its(:message_type) { is_expected.to eq :PlaceOrder }
    its(:message_id) { is_expected.to eq 3 }
#    its(:local_id) { is_expected.to eq 123 }

    it 'has class accessors as well' do
      expect( subject.class.message_type).to eq :PlaceOrder
      expect( subject.class.message_id).to eq 3
      expect( subject.class.version).to be_zero
    end


    it 'encodes correctly' do
      expect( subject.encode[0]). to eq [3, 123, []]                    # msg-id, local_id
      expect( subject.encode[1]). to eq ['', 'F','STK','','','','','SMART','','USD','','', "",""] #  contract
      expect( subject.encode[2] ).to eq [ nil, 100, "LMT",25,"" ] # basic order fields
      expect( subject.encode[3] ).to eq [ "DAY", nil, nil,"O",0,nil,true, 0, false, false, nil, 0, false, false ] # extended order fields
      expect( subject.encode[4]). to eq []                  # empty legs
      if subject.server_version < 177
        expect( subject.encode[5]). to eq  ["",0,nil,nil,[nil,nil,nil,nil]]       # advisory order fields
      else
        expect( subject.encode[5]). to eq  ["",0,nil,nil,[nil,nil,nil]]       # advisory order fields
      end
      expect( subject.encode[6 .. 12]). to eq ["",0,"",-1,0,nil,nil] # regulatory order fields
      expect( subject.encode[ 13  .. 22]). to eq [false, "", "", false, false, "", 0, [ nil, "", "", "", ""], false, ["", ""]]  # algo order fields -1-
      expect( subject.encode[23]). to eq ["",""]                  # empty delta neutral order fields
      expect( subject.encode[24 .. 25]). to eq [0,""]
      expect(subject.encode[26 .. -1]). to eq [  "", "", ["", "", "", "", "", ""], nil, [], false, nil, nil, false, [false], [""], "", false, "", false, [false, false], [], [0], ["", nil, nil, nil, nil, nil, nil], "", [nil, nil], nil, [[nil, nil], [nil, nil]], nil, nil, nil, "", nil, nil, nil, []]

# debug     puts  subject.encode[24 .. -1 ].then{|y| "\n[ #{y} ]"}
    end


  end
end # describe IB::Messages:Outgoing
