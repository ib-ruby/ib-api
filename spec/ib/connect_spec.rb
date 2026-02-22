require "main_helper"
require 'rspec/given'

describe "Connect to Gateway or TWS"  do
  before(:all){ establish_connection }

  after(:all) { close_connection }

  context "A new connection" do
    Given( :connection ){ IB::Connection.current }
    Then { connection.is_a?  IB::Connection }
  end

  context "Workflow States " do
    context "ready" do
      Given( :connection ){ IB::Connection.current }

      Then { connection.ready? }
      Then { connection.workflow_state == 'ready' }
    end

    context "disconnected"  do
#      Given( :connection ){ IB::Connection.current }
      it "initiate disconnect" do 


      ib =  IB::Connection.current
      expect { ib.disconnect! }.to change { ib.workflow_state }.to 'disconnected'
      expect( ib.disconnected?  ).to be_truthy
      expect( ib.ready? ).to be_falsy
      end
    end
  end
    
    
#    it "the received array is active" do
#      expect( IB::Connection.current.received).to be_an Hash
#      expect( IB::Connection.current.received.keys).to include  :Alert
#    end
#
#    it "clients are NOT present"  do
#      expect{ IB::Connection.current.clients }.to raise_error NoMethodError
#    end
#    it "can be disconnected" do
#  end
#
  context "load plugins in the fly" do

    it "connection-tools can be loaded in ready state"  do
      ib =  IB::Connection.current
      expect { ib.try_connection! }.to change{ ib.workflow_state }.to 'ready'
      expect( ib.ready? ).to be_truthy
      expect{ ib.check_connection }.to raise_error NoMethodError

      ib.activate_plugin :connection_tools
      expect( ib.check_connection ).to be_truthy
      expect( ib.ready? ).to be_truthy # unchanged


    end

    it "state `account-based operations` can be loaded through managed-accounts plugin" do
      ib =  IB::Connection.current
      expect( ib.workflow_state ).to eq 'ready'
      ib.activate_plugin :managed_accounts , :connection_tools
      expect( ib.workflow_state).to eq "ready"
      expect( ib.plugins ).to include "managed-accounts"
      expect{ ib.clients }.to raise_error NoMethodError
      expect { ib.initialize_managed_accounts! }.to change{ ib.workflow_state }.to 'account_based_operations'
      expect( ib.clients ).to be_a Array
      expect { ib.disconnect! }.to change{ ib.workflow_state }.to 'disconnected'
    end
  end
#

end
