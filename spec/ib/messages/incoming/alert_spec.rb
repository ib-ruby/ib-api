require 'main_helper'

shared_examples_for 'this Alert message' do
  it { should be_an IB::Messages::Incoming::Alert }
  it { should be_warning }
  it { should_not be_error }
  its( :message_type ){ is_expected.to eq :Alert }
  its( :message_id   ){ is_expected.to eq 4 }
  its( :version      ){ is_expected.to eq 2 }
  its( :data         ){ is_expected.not_to  be_empty }
  its( :error_id     ){ is_expected.to eq -1 }
  its( :code         ){ is_expected.to be_between( 2104, 2107 ) }
  its( :message      ){ is_expected.to match /data farm/ }
	## either  "Market data farm connection is OK:cashfarm "
	## or	"HMDS data farm connection is inactive but should be available upon demand.euhmds"
  its(:to_human) { is_expected.to match  /TWS Warning/ }

  it 'has class accessors as well' do
    expect( subject.class.message_id).to eq 4
    expect( subject.class.message_type).to eq :Alert
  end
end

describe IB::Messages::Incoming::Alert do

  context 'Newly instantiated Message' do

    subject do
      IB::Messages::Incoming::Alert.new(
          :version => 2,
          :error_id => -1,
          :code => 2104,
          :message => 'Market data farm connection is OK:cashfarm')
    end

    it_behaves_like 'this Alert message'
  end

  context 'Message received from IB', :connected => true  do

    before(:all) do
			establish_connection
      sleep 0.1  #  wait for alerts to appear
      # puts IB::Connection.current.received.inspect  # in case of failing tests   look for alert messasges
    end

    after(:all) { close_connection }

    subject { IB::Connection.current.received[:Alert].first }

    it_behaves_like 'this Alert message'
  end #
end # describe IB::Messages:Incoming
