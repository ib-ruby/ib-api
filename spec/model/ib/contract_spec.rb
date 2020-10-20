require 'main_helper'
require 'contract_helper'  # provides request_con_id

RSpec.shared_examples 'ContractData Message' do 
	subject{ the_message }
  it { is_expected.to be_an IB::Messages::Incoming::ContractData }
	its( :contract         ){ is_expected.to be_a  IB::Contract }
	its( :contract_details ){ is_expected.to be_a  IB::ContractDetail }
  its( :message_id       ){ is_expected.to eq 10 }
  its( :version          ){ is_expected.to eq 8 }
	its( :buffer           ){ is_expected.to be_empty }
  it 'has class accessors as well' do
    expect( subject.class.message_id).to eq 10
    expect( subject.class.message_type).to eq :ContractData
  end
end

RSpec.describe IB::Contract do

  # uses the SAMPLE Contract specified in spec_helper 

  context IB::Stock, :connected => true do
    before(:all) do
		  establish_connection
			request_con_id   # populate the recieved array with Contract and ContractDetail Message
    end

    after(:all) { close_connection }
		

		it_behaves_like 'a valid Contract Object' do
			let( :the_contract ){ SAMPLE }
		end


	 context '#merge' do
		 subject{ SAMPLE.merge( symbol: 'GE' ) }  # returns a new object
		 its( :object_id ){is_expected.not_to eq SAMPLE.object_id }
		 its( :symbol ){is_expected.to eq 'GE'}
		 its( :con_id ){is_expected.to be_zero}
	 end




	end
end # describe IB::Messages:Incoming

