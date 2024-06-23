require 'main_helper'

RSpec.describe IB::Connection do

  before(:all) do
    establish_connection
    ib =  IB::Connection.current
    ib.activate_plugin 'order-prototypes'
    ib.activate_plugin 'symbols'

  end

  context 'Stop Order Prototype' do

    Given( :soft ){ IB::Stock.new symbol: 'MSFT' }
    When( :order ){ IB::SimpleStop.order size: -100, price: 200, contract: soft, account: ACCOUNT }
    it{ puts order.as_table }
    context "Main Order Fields show a STP Order" do
      Then { order.serialize_main_order_fields  == [ "SELL", 100, "STP", "",200 ] }
    end
    context "Stop Orders are submitted as GTC" do
      Then { order.serialize_extended_order_fields  == ["GTC", nil, ACCOUNT, "O", 0, nil, true, 0, false, false, nil, 0, false, false] }
    end

    context "Other Order fields are zero or empty" do
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
#
end # describe IB::Messages:Outgoing
