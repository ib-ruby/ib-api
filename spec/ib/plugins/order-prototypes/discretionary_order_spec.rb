require 'main_helper'

RSpec.describe IB::Order  do

  before(:all) do
    establish_connection 'gateway'
    ib =  IB::Connection.current
    ib.activate_plugin 'order-prototypes'
    ib.activate_plugin 'symbols'
    ib.activate_plugin 'process-orders'
    ib.activate_plugin 'order-flow'

  end

  context 'Discretionary Order Prototype' do

    Given( :volatile_stock ){ IB::Stock.new symbol: 'TSLA' }
    Given( :size ){ 100 }
    Given( :price){ 380 }       # Public Limit price
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
      it "place tesla" do
        client= IB::Connection.current.clients.detect{| i | i.account == ACCOUNT } 
        tesla_order = IB::Discretionary.order size: 100, price: price, dc: secret
        ## using preview to pretect from unwanted executions
        client.preview order: tesla_order, contract: volatile_stock  
        expect( client.orders.size ).to be > 0 
        expect( client.orders.last.contract).to eq volatile_stock 
      end


    end

  end

end # describe IB::Messages:Outgoing
