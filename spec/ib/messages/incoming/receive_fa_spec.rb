require 'account_helper'



describe IB::Messages::Incoming do


  context 'Message received from IB', :connected => true do
    before(:all) do
			establish_connection
      ib = IB::Connection.current
										 
			ib.send_message :RequestFA, fa_data_type: 3   # alias

      ib.wait_for :ReceiveFA
    end

    after(:all) { close_connection }

    subject { IB::Connection.current.received[:ReceiveFA].first }
		 
    it_behaves_like 'ReceiveFA message'

		it_behaves_like 'Valid Account Object' do
			let( :the_account_object ){ IB::Connection.current.received[:ReceiveFA].first.accounts.first  }  
		end
  end #
end # describe IB::Messages:Incoming
