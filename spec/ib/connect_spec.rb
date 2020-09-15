require "main_helper"

describe "Connect to Gateway or TWS"  do
	before(:all) do
	establish_connection
	end
	context "A new connection" do
		it{ expect( IB::Connection.current ).to be_a IB::Connection }
	end

end
