require 'main_helper'

RSpec.describe IB::Order  do

  before(:all) do
    establish_connection 'gateway'
    ib =  IB::Connection.current
    ib.activate_plugin 'order-prototypes'
    ib.activate_plugin 'symbols'

  end

  context 'Discretionary Order Prototype' do

    Given( :volatile_stock ){ IB::Stock.new symbol: 'TSLA' }
    Given( :size ){ 100 }
    Given( :price){ 180 }       # Public Limit price
    Given( :secret ){ 5 }       # Secret discount offered to the seller
    When( :order ){ IB::Discretionary.order size: size,
                                           price: price,
                                              dc: secret,
                                        contract: volatile_stock,
                                         account: ACCOUNT }
    it { puts order.as_table }
    context "Main Order Fields show a Limit Order" do
      Then { order.serialize_main_order_fields  == [ "BUY", size, "LMT", price, ""] }
    end
    context "Limit Orders are submitted as GTC" do
      Then { order.serialize_extended_order_fields  == ["GTC", nil, ACCOUNT, "O", 0, nil, true, 0, false, false, nil, 0, false, false] }
    end
    context "The disretionary amount order field is set" do
      Then { order.serialize_auxilery_order_fields.flatten.compact  == [ "", secret ] }
    end
    context "Other Fields are zero or empty" do
      Then { order.serialize_volatility_order_fields.uniq == [ "" ] }
      Then { order.serialize_conditions  == [ 0 ] }
      Then { order.serialize_algo  == [ "" ] }
      Then { order.serialize_scale_order_fields.uniq ==  [""] }
      Then { order.serialize_delta_neutral_order_fields.uniq == [ "" ] }
      Then { order.serialize_pegged_order_fields.empty? }
      Then { order.serialize_mifid_order_fields.flatten.compact.empty? }
      Then { order.serialize_peg_best_and_mid.empty? }
    end

    context "place example orders" do
      Given( :account  ){ IB::Connection.current.clients.detect{| i | i.account == ACCOUNT } }
      When( :order_id ){ account.place order: order, contract: volatile_stock }
      Then{ account.orders.size > 0 }
      Then{ account.orders.last.contract == volatile_stock }


    end

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
