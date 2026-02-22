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

  context 'Pegged to Stock order to dynamically sell a put  option on IBM' do

    Given( :option ){ IB::Symbols::Options.ibm.merge( strike: 150 )}
    Given( :starting_price ){ 2 }
    Given( :delta ){ 0.2  }
    Given( :size ){ -1  }

    When( :order ){ IB::Pegged2Stock.order size: size, delta: delta, starting_price: starting_price,
                                       contract: option, account: ACCOUNT }
    it{ puts order.as_table }
    context "Main Order Fields show a PEG STK order" do
      Then { order.serialize_main_order_fields  == [ "SELL", 1, "PEG STK", "", "" ] }
    end
    context "Pegged orders are submitted as daily orders" do
      Then { order.serialize_extended_order_fields  == ["DAY", nil, ACCOUNT, "O", 0, nil, true, 0, false, false, nil, 0, false, false] }
    end
    context "Advanced option creteria apply" do
      Then { order.serialize_advanced_option_order_fields ==  [ starting_price, "", delta, "", "" ] }
       
    end
    context "Other order fields are zero or empty" do
      Then { order.serialize_auxilery_order_fields.flatten.compact  == [ "", 0 ] }
      Then { order.serialize_volatility_order_fields.uniq == [ "" ] }
      Then { order.serialize_conditions  == [ 0 ] }
      Then { order.serialize_algo  == [ "" ] }
      Then { order.serialize_scale_order_fields.uniq ==  [""] }
      Then { order.serialize_delta_neutral_order_fields.uniq == [ "" ] }
      Then { order.serialize_pegged_order_fields.empty? }
      Then { order.serialize_mifid_order_fields.flatten.compact.empty? }
      Then { order.serialize_peg_best_and_mid.empty? }

#      it{ puts IB::Messages::Outgoing::PlaceOrder.new( local_id: 2, contract: option, order: order ).to_s }
    end

  end
end
