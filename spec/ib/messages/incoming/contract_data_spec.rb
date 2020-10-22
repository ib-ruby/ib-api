require 'main_helper'
require 'contract_helper'  # provides request_con_id


RSpec.describe IB::Messages::Incoming::ContractData do

  context IB::Stock  do
    before(:all) do
		  establish_connection
      ib = IB::Connection.current
			ib.send_message :RequestContractDetails, contract: IB::Contract.new( sec_type: 'STK', symbol: 'GE', currency: 'USD', exchange:'SMART' )
      ib.wait_for :ContractDetailsEnd
    end

    after(:all) { close_connection }
		
#		it_behaves_like 'ContractData Message' do
#			let( :the_message ){ IB::Connection.current.received[:ContractData].first  }  
#		end

		it "inspects" do  # debugging
 		ib = IB::Connection.current
			contract =  ib.received[:ContractData].contract.last
			contract_details =  ib.received[:ContractData].contract_details.last

			puts contract.inspect
			puts contract_details.inspect
		end

	end
end # describe IB::Messages:Incoming

