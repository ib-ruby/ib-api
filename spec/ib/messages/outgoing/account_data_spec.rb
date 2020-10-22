require 'main_helper'

describe IB::Messages::Outgoing  do

  context 'Newly instantiated Message' do

    subject do
      IB::Messages::Outgoing::RequestAccountData.new(
        :subscribe => true,
      :account_code => 'DUH')
    end

    it { is_expected.to be_an IB::Messages::Outgoing::RequestAccountData }
    its(:message_type) { is_expected.to eq :RequestAccountData }
    its(:message_id) { is_expected.to eq 6 }
    its(:data) { is_expected.to eq({:subscribe=>true, :account_code=>"DUH"})}
    its(:subscribe) { is_expected.to be_truthy }
    its(:account_code) { is_expected.to eq 'DUH' }
    its(:to_human) { is_expected.to match  /RequestAccountData/ }

    it 'has class accessors as well' do
      expect( subject.class.message_type).to eq :RequestAccountData
      expect( subject.class.message_id).to eq 6
      expect( subject.class.version).to eq 2
    end

    it 'encodes into Array' do
      expect( subject.encode).to eq  [[6, 2], [], [true, "DUH"]]
    end

    it 'that is flattened before sending it over socket to IB server' do
      expect( subject.preprocess).to eq [6, 2, 1, "DUH"]
    end

    it 'and has correct #to_s representation' do
      expect(subject.to_s).to eq "6-2-1-DUH"
    end

  end
end # describe IB::Messages:Outgoing
