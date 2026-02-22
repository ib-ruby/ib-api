require 'main_helper'


shared_examples_for 'HeadTimeStamp message' do
  it { is_expected.to be_an IB::Messages::Incoming::HeadTimeStamp }
  its(:message_type) { is_expected.to eq :HeadTimeStamp }
  its(:message_id) { is_expected.to eq 88 }
  its(:request_id) {is_expected.to eq 123}
  its(:date) { is_expected.to be_a Time }
  its(:to_human) { is_expected.to match  /First Historical Datapoint/ }

  it 'has class accessors as well' do
    expect( subject.class.message_id).to eq 88 
    expect( subject.class.message_type).to eq :HeadTimeStamp
  end
end

describe IB::Messages::Incoming do

  context 'Newly instantiated Message' do

    subject do
      IB::Messages::Incoming::HeadTimeStamp.new(
          :request_id => 123,
          :date =>  Time.new )
    end

    it_behaves_like 'HeadTimeStamp message'
  end

puts "\n\nIf the second call to »behaves like HeadTimeStamp message« fails, choose a contract with market-data permissions\n\(modify spec.yml)\n"

  context "Message for #{SAMPLE.to_human} received from IB", :connected => true  do

    before(:all) do
      establish_connection
      ib = IB::Connection.current
      ib.send_message :RequestHeadTimeStamp, request_id: 123, contract: SAMPLE # IB::Stock.new(symbol: 'GE')
      ib.wait_for :HeadTimeStamp, 3
    end

    after(:all) { close_connection }
    subject { IB::Connection.current.received[:HeadTimeStamp].first }
     
    it_behaves_like 'HeadTimeStamp message'
  end #
end # describe IB::Messages:Incoming
