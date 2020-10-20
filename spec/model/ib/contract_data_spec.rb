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

RSpec.describe IB::Messages::Incoming::ContractData do

  # uses the SAMPLE Contract specified in spec_helper 
	
  context IB::Stock, :connected => true do
    before(:all) do
		  establish_connection
			request_con_id   # populate the recieved array with Contract and ContractDetail Message
    end

    after(:all) { close_connection }
		
		it_behaves_like 'ContractData Message' do
			let( :the_message ){ IB::Connection.current.received[:ContractData].first  }  
		end


		it_behaves_like 'a complete Contract Object' do
			let( :the_contract ){ IB::Connection.current.received[:ContractData].first.contract }
		end
#		it "inspects" do  # debugging
#			ib = IB::Connection.current
#			contract =  ib.received[:ContractData].contract.first
#			contract_details =  ib.received[:ContractData].contract_details.first
#
#			puts contract.inspect
#			puts contract_details.inspect
#		end

	end
end # describe IB::Messages:Incoming

