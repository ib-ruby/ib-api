require 'main_helper'

RSpec.shared_examples 'Open Position Message' do
  subject{ the_message }
  it { is_expected.to be_an IB::Messages::Incoming::OpenOrder }
  its( :message_type) { is_expected.to eq :OpenOrder }
  its( :contract    ) { is_expected.to be_a IB::Contract }
  its( :message_id  ) { is_expected.to eq 5 }
  its( :client_id   ) { is_expected.to eq 2000 }
  its( :buffer      ) { is_expected.to be_empty }

  it 'has class accessors as well' do
    expect( subject.class.message_id).to eq 5
    expect( subject.class.message_type).to eq :OpenOrder
  end
end
RSpec.shared_examples 'Standard Limit Order' do
  #  covers most of attributes filled directly through `def_message`
  subject{ the_message.order }

  its( :order_type ) { is_expected.to  eq  :limit }
  its( :aux_price  ) { is_expected.to  be_zero }
  its( :tif  ) { is_expected.to  eq :good_till_cancelled }  #  todo test other states, too
  its( :oca_group ) { is_expected.to  be_empty }
  its( :good_after_time ) { is_expected.to  be_empty }
  its( :good_till_date ) { is_expected.to  be_empty }
  its( :account ) { is_expected.to match /\w\d/ }
  its( :open_close ) { is_expected.to  eq :open }
  its( :origin ) { is_expected.to eq :customer }
  its( :order_ref ) { is_expected.to be_empty }  #  customer defined reference
  its( :client_id   ) { is_expected.to eq 2000 }
#  its( :perm_id  ) { is_expected.to match /\d{7,9}/ }
  its( :outside_rth ) { is_expected.to  be false }
  its( :hidden ) { is_expected.to  be false }
  its( :discretionary_amount ) { is_expected.to  be_zero  }

  its( :fa_group ) { is_expected.to be_empty }
  its( :fa_method ) { is_expected.to be_empty }
  its( :fa_percentage ) { is_expected.to be_empty }
  its( :fa_profile ) { is_expected.to be_empty }

  its( :model_code ) { is_expected.to be_empty }
  its( :rule_80a ) { is_expected.to be_nil }       ### todo :  empty?? 
  its( :percent_offset ) { is_expected.to be_nil } ### todo :   zero?? 
  its( :settling_firm  ) { is_expected.to be_empty }
  its( :short_sale_slot ) { is_expected.to eq :default }
  its( :designated_location ) { is_expected.to be_empty }
  its( :exempt_code ) { is_expected.to eq -1 }
  its( :auction_strategy ) { is_expected.to eq :none }
  its( :starting_price ) { is_expected.to be_nil }
  its( :stock_ref_price ) { is_expected.to be_nil }
  its( :delta ) { is_expected.to be_nil }
  its( :stock_range_lower ) { is_expected.to be_nil }
  its( :stock_range_upper ) { is_expected.to be_nil }
  its( :display_size ) { is_expected.to  be_nil }  ### unset if  MAX_INT is transmitted
  its( :block_order ) { is_expected.to be false }
  its( :sweep_to_fill ) { is_expected.to be false }
  its( :all_or_none ) { is_expected.to be false }
  its( :min_quantity  ) { is_expected.to  be_nil }
  its( :oca_type) { is_expected.to  eq :reduce_no_block }  # 3
  #  etrade 
  its( :firm_quote_only  ) { is_expected.to  be false }
  its( :nbbo_price_cap ) { is_expected.to  be_empty }
  its( :parent_id  ) { is_expected.to  be_zero }
  its( :trigger_method ) { is_expected.to eq :default }
  its( :volatility  ) { is_expected.to  be_nil }
  its( :volatility_type  ) { is_expected.to  be_nil }
  its( :delta_neutral_order_type ){ is_expected.to  eq :none  }  #  see constants#210
  its( :delta_neutral_aux_price ) { is_expected.to  be_nil  }
end


RSpec.shared_examples 'Extended Limit Order' do
  #  covers attributes filled  through load_map
  subject{ the_message.order }

  its( :continuous_update ) { is_expected.to be_zero }
  its( :reference_price_type ) { is_expected.to be_nil }
  its( :trail_stop_price ) { is_expected.to be_nil }
  its( :trailing_percent ) { is_expected.to be_nil }
  its( :basis_points ) { is_expected.to be_nil }
  its( :basis_points_type ) { is_expected.to be_nil }

  its( :leg_prices ) { is_expected.to be_a Array }
  its( :leg_prices ) { is_expected.to be_empty }
  its( :combo_params ) { is_expected.to be_a Array  }  # todo Needs testing with combo_params
                                                       # should be a Hash, ... support.rb --> read_hash
  its( :combo_params ) { is_expected.to be_empty }

  its( :scale_init_level_size ) { is_expected.to be_nil }
  its( :scale_subs_level_size ) { is_expected.to be_nil }
  its( :scale_price_increment ) { is_expected.to be_nil }

  its( :hedge_type ) { is_expected.to be_nil }
  its( :opt_out_smart_routing ) { is_expected.to be false }
  its( :clearing_account ) { is_expected.to be_empty }
  its( :clearing_intent ) { is_expected.to eq :ib }
  its( :not_held ) { is_expected.to be false }
  its( :algo_strategy ) { is_expected.to be_empty }
  its( :solicided ) { is_expected.to be false }
  its( :what_if ) { is_expected.to be false }
  its( :random_size ) { is_expected.to be false }
  its( :random_price ) { is_expected.to be false }
  its( :conditions ) { is_expected.to be_empty }

  its( :adjusted_order_type ) { is_expected.to eq "None" }
  its( :trigger_price ) { is_expected.to be_nil }
  its( :trail_stop_price ) { is_expected.to be_nil }
  its( :limit_price_offset ) { is_expected.to be_nil }
  its( :adjusted_stop_price ) { is_expected.to be_nil }
  its( :adjusted_stop_limit_price ) { is_expected.to be_nil }
  its( :adjusted_trailing_amount ) { is_expected.to be_nil }
  its( :adjustable_trailing_unit ) { is_expected.to be_zero }  #  only integer allowed

  its( :soft_dollar_tier_name ) { is_expected.to be_empty }
  its( :soft_dollar_tier_value ) { is_expected.to be_empty }
  its( :soft_dollar_tier_display_name ) { is_expected.to be_empty }

  its( :cash_qty ) { is_expected.to be_zero }  # 0.0
  its( :dont_use_auto_price_for_hedge ) { is_expected.to be true }
  its( :is_O_ms_container ) { is_expected.to be false }
  its( :discretionary_up_to_limit_price ) { is_expected.to be false }
  its( :use_price_management_algo ) { is_expected.to be false }
  its( :duration ) { is_expected.to be_nil }
  its( :post_to_ats ) { is_expected.to be_nil }
  its( :auto_cancel_parent) { is_expected.to be false }

end

RSpec.shared_examples 'Extended OrderState attributes' do
  #  covers attributes filled  through load_map
  subject{ the_message.order_state }
  its( :status ) { is_expected.to eq "Submitted" }            # OrderState attributes are nil
  its( :init_margin_before ) { is_expected.to be_nil }               # if what_if is not set
  its( :maint_margin_before ) { is_expected.to be_nil }
  its( :equity_with_loan_before ) { is_expected.to be_nil }
  its( :init_margin_change ) { is_expected.to be_nil }               # if what_if is not set
  its( :maint_margin_change ) { is_expected.to be_nil }
  its( :equity_with_loan_change ) { is_expected.to be_nil }
  its( :init_margin_after ) { is_expected.to be_nil }               # if what_if is not set
  its( :maint_margin_after ) { is_expected.to be_nil }
  its( :equity_with_loan_after ) { is_expected.to be_nil }
  its( :commission ) { is_expected.to be_nil }
  its( :min_commission ) { is_expected.to be_nil }
  its( :max_commission ) { is_expected.to be_nil }
  its( :commission_currency ) { is_expected.to be_empty }
  its( :warning_text ) { is_expected.to be_empty }

end

RSpec.shared_examples 'empty Combo Order attributes' do
  #  covers attributes filled  through load_map
  subject{ the_message.contract }
  its( :legs_description ) { is_expected.to be_empty }
  its( :combo_legs ) { is_expected.to be_a Array }
  its( :combo_legs ) { is_expected.to be_empty }
end
RSpec.describe IB::Messages::Incoming::OpenOrder do

  context "Syntetic Message" do
    let( :the_message ) do
      IB::Messages::Incoming::OpenOrder.new(
 ["4", "14217", "SIE", "STK", "", "0", "?", "", "SMART", "EUR", "SIE", "XETRA", "BUY", "1", "LMT", "70.0", "0.0", "GTC", "", "DU4035275", "", "0", "", "2000", "727847514", "0", "0", "0", "", "", "", "", "", "", "", "", "0", "", "", "0", "", "-1", "0", "", "", "", "", "", "2147483647", "0", "0", "0", "", "3", "0", "0", "", "0", "0", "", "0", "None", "", "0", "", "", "", "?", "0", "0", "", "0", "0", "", "", "", "", "", "0", "0", "0", "2147483647", "2147483647", "", "", "0", "", "IB", "0", "0", "", "0", "0", "Submitted", "1.7976931348623157E308", "1.7976931348623157E308", "1.7976931348623157E308", "1.7976931348623157E308", "1.7976931348623157E308", "1.7976931348623157E308", "1.7976931348623157E308", "1.7976931348623157E308", "1.7976931348623157E308", "", "", "", "", "", "0", "0", "0", "None", "1.7976931348623157E308", "1.7976931348623157E308", "1.7976931348623157E308", "1.7976931348623157E308", "1.7976931348623157E308", "1.7976931348623157E308", "0", "", "", "", "0", "1", "0", "0", "0", "", "", "0"]
                       ## trailing_unit               |
                                             ##cash_qty
)
    end

    it "has the basic attributes" do
      expect( the_message.local_id ).to eq 4
      expect( the_message.contract.symbol ).to eq 'SIE'
      puts the_message.inspect
    end
    it "references to the right contract" do
      siemens =  IB::Stock.new symbol: 'SIE', exchange: 'SMART', currency: 'EUR',
                               exchange: 'XETRA'
      expect( the_message.contract ).to eq siemens
    end

    it "references to the correct order" do
      expect( the_message.order.perm_id  ).to eq  727847514
      expect( the_message.order.action  ).to eq  :buy
      expect( the_message.order.total_quantity  ).to eq  1
      expect( the_message.order.limit_price  ).to eq  70
    end
    it_behaves_like 'Open Position Message'
    it_behaves_like 'Standard Limit Order'
    it_behaves_like 'Extended OrderState attributes'
    it_behaves_like 'Extended Limit Order'
    it_behaves_like 'empty Combo Order attributes'

    end
#  context 'Message received from IB', :connected => true  do
#    before(:all) do
#     establish_connection
#      ib = IB::Connection.current
#     ib.send_message :RequestPositionsMulti, request_id: 204, account: ACCOUNT
#      ib.wait_for :PositionsMulti, 10
#     sleep 1
#     ib.send_message :CancelPositionsMulti, :subscribe => false
#    end
#
#    after(:all) { close_connection }
#
#   it_behaves_like 'Position Message' do
#     let( :the_message ){ IB::Connection.current.received[:PositionsMulti].first  }
#   end
#

#  end #
end # describe IB::Messages:Incoming

