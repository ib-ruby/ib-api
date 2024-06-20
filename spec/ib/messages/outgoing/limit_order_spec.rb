require 'main_helper'

RSpec.describe IB::Messages::Outgoing  do

  before(:all) do
    establish_connection
    ib =  IB::Connection.current
    ib.activate_plugin 'order-prototypes'
    ib.activate_plugin 'symbols'

  end

  context 'Stock' do

    Given( :soft ){ IB::Symbols::Stocks.msft }
    When( :limit_order ){ IB::Limit.order size: 100, price: 200, contract: soft, account: ACCOUNT }
    Then { limit_order.serialize_main_order_fields  == [ "BUY", 100, "LMT", 200, ""] }
    Then { limit_order.serialize_extended_order_fields  == ["GTC", nil, ACCOUNT, "O", 0, nil, true, 0, false, false, nil, 0, false, false] }
    Then { limit_order.serialize_auxilery_order_fields  == ["", 0, nil, nil, [nil, nil, nil, nil]] }
    Then { limit_order.serialize_conditions  == [ 0 ] }
    Then { limit_order.serialize_algo  == [ "" ] }
    Then { limit_order.serialize_volatility_order_fields == [ "", ""] }
    Then { limit_order.serialize_scale_order_fields ==  ["", "", "", "", "", ""] }
    Then { limit_order.serialize_delta_neutral_order_fields == [ "", ""] }
    Then { limit_order.serialize_pegged_order_fields == [] }
    Then { limit_order.serialize_mifid_order_fields == [[nil, nil], [nil, nil]] }
    Then { limit_order.serialize_peg_best_and_mid == [] }

  end

#
#    subject do
#      IB::Messages::Outgoing::PlaceOrder.new(
#				local_id: 123,
#        contract:  IB::Stock.new( symbol: 'F' ),
#        order: IB::Order.new( total_quantity: 100, limit_price: 25, tif: :good_til_canceled ))
#    end
#
#    it { should be_an IB::Messages::Outgoing::PlaceOrder }
#    its(:message_type) { is_expected.to eq :PlaceOrder }
#    its(:message_id) { is_expected.to eq 3 }
##    its(:local_id) { is_expected.to eq 123 }
#
#    it 'has class accessors as well' do
#      expect( subject.class.message_type).to eq :PlaceOrder
#      expect( subject.class.message_id).to eq 3
#      expect( subject.class.version).to be_zero
#    end
#
#
#    it 'encodes correctly' do
#      expect( subject.encode[0]). to eq [3, 123, []]										# msg-id, local_id
#      expect( subject.encode[1]). to eq ['', 'F','STK','','','','','SMART','','USD','','', "",""]	#  contract
#      expect( subject.encode[2] ).to eq [ nil, 100, "LMT",25,"" ]	# basic order fields
#      expect( subject.encode[3] ).to eq [ "DAY", nil, nil,"O",0,nil,true, 0, false, false, nil, 0, false, false ]	# extended order fields
##      expect( subject.encode[4]). to eq [[],[]]									# empty legs
##      expect( subject.encode[5]). to eq ["",0,nil,nil]					# auxilery order fields
#      if subject.server_version < 177
#        expect( subject.encode[4]). to eq  ["",0,nil,nil,[nil,nil,nil,nil]]       # advisory order fields
#      else
#        expect( subject.encode[4]). to eq  ["",0,nil,nil,[nil,nil,nil]]       # advisory order fields
##     expect( subject.encode[6]). to eq [nil,nil,nil]       # advisory order fields
#      end
##      expect( subject.encode[7]). to eq ["",0,"",-1,0,nil,nil]	# regulatory order fields
##      expect( subject.encode[8]). to eq [false, "", "", false, false, false, 0, nil, "", "", "", "", false, ["", ""]]	# algo order fields -1-
##      expect( subject.encode[9]). to eq ["",""]									# empty delta neutral order fields
##      expect( subject.encode[10]). to eq [0,""]									# empty delta neutral order fields
#
#    end
#
#
end # describe IB::Messages:Outgoing
