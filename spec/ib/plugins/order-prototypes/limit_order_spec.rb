require 'main_helper'

RSpec.describe IB::Order  do

  before(:all) do
    establish_connection
    ib =  IB::Connection.current
    ib.activate_plugin 'order-prototypes'
    ib.activate_plugin 'symbols'

  end

  context 'Limit Order Prototype' do

    Given( :soft ){ IB::Stock.new symbol: 'MSFT' }
    Given( :size ){ 100 }
    Given( :price){ 200 }
    When( :order ){ IB::Limit.order size: size, price: price, contract: soft, account: ACCOUNT }
    it { puts order.as_table }
    context "Main Order Fields show a Limit Order" do
      Then { order.serialize_main_order_fields  == [ "BUY", size, "LMT", price, ""] }
    end
    context "Limit Orders are submitted as GTC" do
      Then { order.serialize_extended_order_fields  == ["GTC", nil, ACCOUNT, "O", 0, nil, true, 0, false, false, nil, 0, false, false] }
    end
    context "Other Fields are zero or empty" do
      Then { order.serialize_auxilery_order_fields.flatten.compact  == [ "", 0 ] }
      Then { order.serialize_volatility_order_fields.uniq == [ "" ] }
      Then { order.serialize_conditions  == [ 0 ] }
      Then { order.serialize_algo  == [ "" ] }
      Then { order.serialize_scale_order_fields.uniq ==  [""] }
      Then { order.serialize_delta_neutral_order_fields.uniq == [ "" ] }
      Then { order.serialize_pegged_order_fields.empty? }
      Then { order.serialize_mifid_order_fields.flatten.compact.empty? }
      Then { order.serialize_peg_best_and_mid.empty? }
    end

  end

#
end # describe IB::Messages:Outgoing
