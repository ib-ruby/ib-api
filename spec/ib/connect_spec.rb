require "main_helper"

describe "Connect to Gateway or TWS"  do
	before(:all){ establish_connection }

  after(:all) { close_connection }
	
	context "A new connection" do
		it{ expect( IB::Connection.current ).to be_a IB::Connection }
	end

end
