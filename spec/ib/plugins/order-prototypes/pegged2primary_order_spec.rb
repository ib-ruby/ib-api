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

  context 'Pegged to Primary Order Prototype with a price cap' do

    Given( :stock ){ IB::Stock.new symbol: "MSFT"}

    When( :order ){ IB::Pegged2Primary.order size: 100, price_cap: 450, offset_amount: 0.1,
                                         contract: stock, account: ACCOUNT }
    it{ puts order.as_table }
    context "Main Order Fields show a REL order" do
      Then { order.serialize_main_order_fields  == [ "BUY", 100, "REL", 450, 0.1 ] }
    end
    context "Pegged orders are submitted as daily orders" do
      Then { order.serialize_extended_order_fields  == ["DAY", nil, ACCOUNT, "O", 0, nil, true, 0, false, false, nil, 0, false, false] }
    end
    context "Normal order nns apply" do
      Then { order.serialize_auxilery_order_fields.flatten.compact  == [ "", 0 ] }
      Then { order.serialize_volatility_order_fields.uniq == [ "" ] }
      Then { order.serialize_conditions  == [ 0 ] }
      Then { order.serialize_scale_order_fields.uniq ==  [""] }
      Then { order.serialize_delta_neutral_order_fields.uniq == [ "" ] }
      Then { order.serialize_pegged_order_fields.empty? }
      Then { order.serialize_mifid_order_fields.flatten.compact.empty? }
      Then { order.serialize_peg_best_and_mid.empty? }
    end

  end
end
