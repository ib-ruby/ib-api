require 'order_helper'

# *notice*
#  The tests below pass only if no open or pending order is present


describe "Order-Flow", :connected => true, :integration => true, :slow => true do

  before(:all) do
    establish_connection
    ib =  IB::Connection.current
    ib.activate_plugin :symbols, :order_prototypes, :order_flow
  end

  context "Trading Ford", :if => :forex_trading_hours, focus: true do

    before(:all) do
      ib = IB::Connection.current
      @initial_order_id =  ib.next_local_id
    end

    after(:all) { remove_open_orders; close_connection }

    let(:contract) { IB::Symbols::Stocks.sie }
    [ :buy, :sell ].each_with_index do | the_action, count |
       context "Placing #{the_action.to_s.upcase} order"  do


         it " place the order" do
           order =  IB::Market.order( size: 2,
                                    action: the_action,
                                   account: ACCOUNT,
                                  contract: contract )
          open_order =  order.place
          expect( open_order).to be_a IB::Order
          puts open_order &.to_human
         end  # it
       end    # each
    end       # context
  end         # context
#      context IB::Connection  do
#      subject{  IB::Connection.current  }
#      it { expect( subject.received[:OpenOrder]).to have_at_least(1).open_order_message }
#      it { expect( subject.received[:OrderStatus]).to have_at_least(1).status_message }
#      it { expect( subject.received[:ExecutionData]).to have_exactly(1).execution_data }
#      it { expect( subject.received[:CommissionReport]).to have_exactly(1).report }
#
#      end
#
#
#
#      context IB::Messages::Incoming::OpenOrder do
#        subject{ IB::Connection.current.received[:OpenOrder].first }
#        it_behaves_like 'OpenOrder message'
#      end
#
#      context IB::Order do
#        subject{ IB::Connection.current.received[:OpenOrder].last.order }
##       it{ is_expected.to eql @order  }  uncomment to display the difference between the
#        #                                 order send to the tws and the response after filling
#        it_behaves_like 'Placed Order'
#        it_behaves_like 'Filled Order'
#      end
#
#      context IB::Messages::Incoming::ExecutionData do
#        subject { IB::Connection.current.received[:ExecutionData].last }
#        it_behaves_like 'Proper Execution Record' , the_action
#      end
#
#      context IB::Messages::Incoming::CommissionReport do
#        subject{ IB::Connection.current.received[:CommissionReport].last }
#        it_behaves_like 'Valid CommissionReport' , count
#      end
#
#    end # Placing 
#     end # each
#
#    context "Request executions" do
#
#      before(:all) do
#        ib =  IB::Connection.current
#        @request_id = ib.send_message :RequestExecutions,
#                         :client_id => OPTS[:connection][:client_id],
#                          account: OPTS[:connection][:account],
#                         :time => (Time.now.utc-10).to_ib # Time zone problems possible
#        ib.wait_for :ExecutionData, 3 # sec
#      end
#
#      after(:all) { clean_connection }
#
#      it 'does not receive Order-related messages' do
#        puts "time"
#        puts  (Time.now.utc-10).to_ib
#        expect( IB::Connection.current.received[:OpenOrder]).to be_empty
#        expect( IB::Connection.current.received[:OrderStatus]).to be_empty
#      end
#
#      it 'receives ExecutionData messages' do
#        expect( IB::Connection.current.received[:ExecutionData]).to have_at_least(1).execution_data
#      end
#
#
#      it 'also receives Commission Reports' do
#        expect( IB::Connection.current.received[:CommissionReport]).to have_at_least(2).reports
#      end
#

end # Trades

__END__

