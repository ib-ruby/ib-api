require 'main_helper'

##  call with
##  it_behaves_like 'Valid Account Object' do
##      let( :the_account_object ){ some_object }
##    end
shared_examples_for 'Valid Account Object' do
    subject{ the_account_object }
    it{ is_expected.to be_a IB::Account }
    its( :account) { is_expected.to be_a String }
    its( :save ){ is_expected.to be_truthy }
end
##  call with
##  it_behaves_like 'Valid AccountValue Object' do
##      let( :the_account_value_object ){ some_object }
##    end
shared_examples_for 'Valid AccountValue Object' do
    subject{ the_account_value_object }
    it { is_expected.to be_a IB::AccountValue }
    its( :key ) { is_expected.to be_a Symbol }
    its( :value ) { is_expected.to be_a String }
    its( :currency ) { is_expected.to be_a String }
end

### Helpers for placing and verifying orders  ### old
# 
shared_examples_for 'Valid account data request' do

  context "received :AccountUpdateTime message" do
    subject { IB::Connection.current.received[:AccountUpdateTime].first }

    it { is_expected.to be_an IB::Messages::Incoming::AccountUpdateTime }
    its(:data) { is_expected.to be_a Hash }
    its(:time_stamp) { is_expected.to  match /\d\d:\d\d/ }
    its(:to_human) { is_expected.to match /AccountUpdateTime/ }
  end

  context "received :AccountValue message" do
    subject { IB::Connection.current.received[:AccountValue].first }

    it { is_expected.to be_an IB::Messages::Incoming::AccountValue }
    its(:data) { is_expected.to be_a Hash }
    its(:account) { is_expected.to match /\w\d/ }
    its(:account_value ){ is_expected.to be_a IB::AccountValue }
#    its(:key) { is_expected.to be_a String }
#    its(:value) { is_expected.to be_a String }
#    its(:currency) { is_expected.to  be_a String }
    its(:to_human) { is_expected.to match /AccountValue/ }
  end

  context "received :PortfolioValue message" do
    subject { IB::Connection.current.received[:PortfolioValue].first }

    it { is_expected.to  be_an IB::Messages::Incoming::PortfolioValue }
    its( :contract ) { is_expected.to  be_a IB::Contract }
    its( :data ) { is_expected.to be_a Hash }
    its( :portfolio_value ){is_expected.to be_a IB::PortfolioValue }
    its( :account ) {  is_expected.to match /\w\d/ }

    its( :to_human ) { is_expected.to match /PortfolioValue/ }
    
#    its(:position) { should be_a BigDecimal }
#    puts 
#    its(:market_price) { should be_a BigDecimal }
#    its(:market_value) { should be_a BigDecimal }
#    its(:average_cost) { should be_a BigDecimal }
#    its(:unrealized_pnl) { should be_a BigDecimal }
#    its(:realized_pnl) { should be_a BigDecimal }
  end

  context "received :AccountDownloadEnd message" do
    subject { IB::Connection.current.received[:AccountDownloadEnd].first }

    it { should be_an IB::Messages::Incoming::AccountDownloadEnd }
    its(:data) { should be_a Hash }
    its(:account_name) { should =~ /\w\d/ }
    its(:to_human) { should =~ /AccountDownloadEnd/ }
  end
end

shared_examples_for 'ReceiveFA message' do
  it { is_expected.to be_an IB::Messages::Incoming::ReceiveFA }
  its(:message_type) { is_expected.to eq :ReceiveFA }
  its(:message_id) { is_expected.to eq 16 }
  its(:accounts) {is_expected.to be_an Array}
  its( :buffer  ){ is_expected.to be_empty }

  it 'has class accessors as well' do
    expect( subject.class.message_id).to eq  16 
    expect( subject.class.message_type).to eq :ReceiveFA
  end
end

