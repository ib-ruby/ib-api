require 'main_helper'

RSpec.describe IB::Connection do

  before(:all) do
    establish_connection
    ib =  IB::Connection.current
    ib.activate_plugin 'verify'
    ib.activate_plugin 'order-prototypes'
    ib.activate_plugin 'symbols'
    ib.activate_plugin 'market-price'

  end


  context 'Pegged Bench order on IBM using  Microsoft as Benchmark' do

    Given( :stock ){ IB::Stock.new( symbol: 'IBM' ) }
    Given( :benchmark ){ IB::Symbols::Stocks.msft_conid } # benchmark is always identified by its conid
    Given( :increment ){ 1 }
    Given( :reference_increment ){ 2 }

    When( :order ){ IB::Pegged2Benchmark.order size: 100, starting_price: 450, change_by:  increment,
                                          reference: benchmark.con_id,
                                reference_change_by: reference_increment,
                                           contract: stock, account: ACCOUNT }
    it{ puts order.as_table }
    context "Main Order Fields show a Pegged to Benchmark  order" do
      Then { order.serialize_main_order_fields  == [ "BUY", 100, "PEG BENCH", "", "" ] }
    end
    context "Pegged orders are submitted as daily orders" do
      Then { order.serialize_extended_order_fields  == ["DAY", nil, ACCOUNT, "O", 0, nil, true, 0, false, false, nil, 0, false, false] }
    end
     context "Pegged order fields are populated" do
       Then { order.serialize_pegged_order_fields == [ benchmark.con_id,
                                                       false,  # increase
                                                       increment,
                                                       reference_increment,
                                                       '' ]  } # reference exchange
     end
    context "Other order fields are zero or empty" do
      Then { order.serialize_auxilery_order_fields.flatten.compact  == [ "", 0 ] }
      Then { order.serialize_volatility_order_fields.uniq == [ "" ] }
      Then { order.serialize_conditions  == [ 0 ] }
      Then { order.serialize_algo  == [ "" ] }
      Then { order.serialize_scale_order_fields.uniq ==  [""] }
      Then { order.serialize_delta_neutral_order_fields.uniq == [ "" ] }
      Then { order.serialize_mifid_order_fields.flatten.compact.empty? }
      Then { order.serialize_peg_best_and_mid.empty? }
    end

  end
end
