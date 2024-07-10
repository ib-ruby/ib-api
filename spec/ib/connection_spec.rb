require "spec_helper"

describe  IB::Connection do
  Given( :ib  ) { IB::Connection.new }
  Then { ib.is_a? IB::Connection }

  # Check if all Messages are defined
  # There are  51 Incoming Message classes
  Given( :in_classes ){ IB::Messages::Incoming::Classes }
  Then{  in_classes.is_a? Hash }
  Then{  in_classes.size == 51 }

  Given( :out_classes ){ IB::Messages::Outgoing::Classes }
  Then{  out_classes.is_a? Hash }
  Then{  out_classes.size == 53 }
end

describe "Connection tests" do
  it "connect to localhost" do
    c = IB::Connection.new host: OPTS[:connection][:host], port: OPTS[:connection][:port]
    expect( c ).to be_a IB::Connection
    c.try_connection!
    expect( c.connected? ).to be_truthy

  end
  it "connect to localhost with host:port syntax" do  # expected: no GUI-TWS is running on localhost
    c = IB::Connection.new host: '127.0.0.1:4001', connect: false
    expect( c ).to be_a IB::Connection
    expect{ c.try_connection! }.to raise_error Errno::ECONNREFUSED

  end
end

