=begin
request con_id for a given  IB::Contract

returns the con_id's

After calling the helper-function, the fetched ContractDetail-Messages are still present in received-buffer 
=end

def request_con_id  contract: SAMPLE

		ib =  IB::Connection.current
		ib.clear_received
		raise 'Unable to verify contract, no connection' unless ib && ib.connected?

		ib.send_message :RequestContractDetails, contract: contract
		ib.wait_for :ContractDetailsEnd

		ib.received[:ContractData].contract.map &:con_id  # return an array of con_id's

end

RSpec.shared_examples 'a complete Contract Object' do 
	subject{ the_contract }
	it_behaves_like 'a valid Contract Object'
  it { is_expected.to be_an IB::Contract }
	its( :contract_detail ){ is_expected.to be_a  IB::ContractDetail }
	its( :primary_exchange){ is_expected.to be_a String }
end
RSpec.shared_examples 'a valid Contract Object' do 
	subject{ the_contract }
  it { is_expected.to be_an IB::Contract }
	its( :con_id          ){ is_expected.to be_empty.or be_a(Numeric) }
	its( :contract_detail ){ is_expected.to be_nil.or be_a(IB::ContractDetail) }
  its( :symbol          ){ is_expected.to be_a String }
  its( :local_symbol    ){ is_expected.to be_a String }
  its( :currency        ){ is_expected.to be_a String }
	its( :sec_type        ){ is_expected.to be_a(Symbol).and satisfy { |sec_type| IB::SECURITY_TYPES.values.include?(sec_type) } }
  its( :trading_class   ){ is_expected.to be_a String }
	its( :exchange        ){ is_expected.to be_a String }
	its( :primary_exchange){ is_expected.to be_nil.or be_a(String) }
end
