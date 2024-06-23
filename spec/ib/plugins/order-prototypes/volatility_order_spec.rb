require 'main_helper'

RSpec.describe IB::Order do

  before(:all) do
    establish_connection
    ib =  IB::Connection.current
    ib.activate_plugin 'verify'
    ib.activate_plugin 'order-prototypes'
    ib.activate_plugin 'symbols'

  end

  context 'Volatility Order Prototype' do

    Given( :strike ){ 2000 }
    Given( :option ){ IB::Symbols::Options.rutw.merge( strike: strike, expiry: IB::Future.next_expiry[0..-3] ).verify.first }

    When( :order ){ IB::Volatility.order size: -1, volatility: 0.2, contract: option, account: ACCOUNT }
    it{ puts order.as_table }
    context "Main Order Fields show a VOL Order" do
      Then { order.serialize_main_order_fields  == [ "SELL", 1, "VOL", "", "" ] }
    end
    context "Volatility Orders are submitted as daily orders" do
      Then { order.serialize_extended_order_fields  == ["DAY", nil, ACCOUNT, "O", 0, nil, true, 0, false, false, nil, 0, false, false] }
    end
    context "Volatility specific orderfields are populated; volatility is expessed annualy" do
      Then { order.serialize_volatility_order_fields == [ 0.2, 2] }
    end
    context "Other order fields are zero or empty" do
      Then { order.serialize_auxilery_order_fields.flatten.compact  == [ "", 0 ] }
      Then { order.serialize_conditions  == [ 0 ] }
      Then { order.serialize_algo  == [ "" ] }
      Then { order.serialize_scale_order_fields.uniq ==  [""] }
      Then { order.serialize_delta_neutral_order_fields.uniq == [ "" ] }
      Then { order.serialize_pegged_order_fields.empty? }
      Then { order.serialize_mifid_order_fields.flatten.compact.empty? }
      Then { order.serialize_peg_best_and_mid.empty? }
    end

  end
end
