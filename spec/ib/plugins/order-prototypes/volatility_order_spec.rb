require 'main_helper'

RSpec.describe IB::Order do

  before(:all) do
    establish_connection
    ib =  IB::Connection.current
    ib.activate_plugin 'verify'
    ib.activate_plugin 'order-prototypes'
    ib.activate_plugin 'symbols'

  end

  STRIKE = 2000

  context 'Volatility order on RUT Options' do

    Given( :option ){ IB::Symbols::Options.rutw.merge( strike: STRIKE, expiry: IB::Future.next_expiry[0..-3] ).verify.first }

    When( :order ){ IB::Volatility.order size: -1, volatility: 20, contract: option, account: ACCOUNT }
    it{ puts order.as_table }
    context "Main Order Fields show a VOL order" do
      Then { order.serialize_main_order_fields  == [ "SELL", 1, "VOL", "", "" ] }
    end
    context "Volatility orders are submitted as daily orders" do
      Then { order.serialize_extended_order_fields  == ["DAY", nil, ACCOUNT, "O", 0, nil, true, 0, false, false, nil, 0, false, false] }
    end
    context "Volatility specific orderfields are populated; volatility is expessed annualy" do
      Then { order.serialize_volatility_order_fields == [ 20, 2] }
    end
    context "Normal order conditions apply" do
      Then { order.serialize_auxilery_order_fields  == ["", 0, nil, nil, [nil, nil, nil, nil]] }
      Then { order.serialize_conditions  == [ 0 ] }
      Then { order.serialize_algo  == [ "" ] }
      Then { order.serialize_scale_order_fields ==  ["", "", "", "", "", ""] }
      Then { order.serialize_delta_neutral_order_fields == [ "", ""] }
      Then { order.serialize_pegged_order_fields == [] }
      Then { order.serialize_mifid_order_fields == [[nil, nil], [nil, nil]] }
      Then { order.serialize_peg_best_and_mid == [] }
    end

  end
end
