require 'main_helper'
require 'order_helper'

RSpec.describe IB::Order  do

  before(:all) do
    establish_connection
    ib =  IB::Connection.current
    ib.activate_plugin 'order-prototypes'
    ib.activate_plugin 'symbols'

  end

  context 'Adaptive Limit Order ' do

    Given( :soft ){ IB::Stock.new symbol: 'MSFT' }
    Given( :size ){ 100 }
    Given( :price){ 200 }
    When( :order ){ IB::Adaptive.order size: size, price: price, contract: soft, account: ACCOUNT }
    it { puts order.as_table }
    context "Main Order Fields show a Limit Order" do
      Then { order.serialize_main_order_fields  == [ "BUY", size, "LMT", price, ""] }
    end
    context "Limit Orders are submitted as GTC" do
      Then { order.serialize_extended_order_fields  == ["GTC", nil, ACCOUNT, "O", 0, nil, true, 0, false, false, nil, 0, false, false] }
    end
    context "Algo specific fields are serialized" do
      Then { order.serialize_algo  == [ "Adaptive", 1, ["adaptivePriority", "Normal"] ] }
    end
    context "Order specifies as Limit" do
      subject{ order }
      it_behaves_like "serialize limit order fields"
    end

  end

end # describe IB::Messages:Outgoing
