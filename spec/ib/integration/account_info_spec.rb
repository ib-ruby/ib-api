require 'integration_helper'

describe "Request Account Data", :connected => true, :integration => true  do

  before(:all){ establish_connection }

  #after(:all) { close_connection }

  context "with subscribe option set" do
    before(:all) do
      ib =  IB::Connection.current
      ib.send_message :RequestAccountData,  subscribe: true , account_code: ACCOUNT
      ib.wait_for :AccountDownloadEnd, 5 # sec
    end
    after(:all) do
      IB::Connection.current.send_message :RequestAccountData,  subscribe: false , account_code: ACCOUNT
      clean_connection
    end

    it_behaves_like 'Valid account data request'
  end

  context "without subscribe option" do
    before(:all) do
      ib =  IB::Connection.current
      ib.send_message :RequestAccountData,  account_code: ACCOUNT
      ib.wait_for :AccountDownloadEnd, 5 # sec
    end

    after(:all) do
      IB::Connection.current.send_message :RequestAccountData,  subscribe: false , account_code: ACCOUNT
      clean_connection
    end

    it_behaves_like 'Valid account data request'
  end
end # Request Account Data
