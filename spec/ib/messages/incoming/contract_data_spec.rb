require 'main_helper'
require 'contract_helper'  # provides request_con_id


RSpec.describe IB::Messages::Incoming::ContractData do

  before(:all) do
      establish_connection
  end

  after(:all) { close_connection }

  context IB::Stock  do
    before(:all) do
      ib = IB::Connection.current
      ib.send_message :RequestContractDetails, contract: IB::Stock.new( symbol: 'GE', currency: 'USD', exchange:'SMART' )
      ib.wait_for :ContractDetailsEnd, :ContractDataEnd
    end

    after(:all){ IB::Connection.current.clear_received :ContractDetails }

#   it_behaves_like 'ContractData Message' do
#     let( :the_message ){ IB::Connection.current.received[:ContractData].first  }
#   end
    context "Basics" do
      subject{  IB::Connection.current.received[:ContractDetails].contract.last }

      it_behaves_like 'a complete Contract Object'
      its( :sec_type ){is_expected.to eq :stock}
      its( :symbol ){is_expected.to eq 'GE'}
      its( :con_id ){is_expected.to eq 498843743}
    end

    context "received a single contract" do
      subject{ IB::Connection.current.received[:ContractDetails]  }
      it{ is_expected.to be_a Array }
      its(:size){is_expected.to eq 1 }
    end
  end


end # describe IB::Messages:Incoming

