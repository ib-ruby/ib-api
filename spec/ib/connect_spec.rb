require "main_helper"

describe "Connect to Gateway or TWS"  do
  before(:all){ establish_connection }

  after(:all) { close_connection }

  context "A new connection" do
    it{ expect( IB::Connection.current ).to be_a IB::Connection }

    it "has the proper state" do
      expect( IB::Connection.current.ready?  ).to be_truthy
      expect( IB::Connection.current.workflow_state  ).to  eq  'ready'
    end
    it "the received array is active" do
      expect( IB::Connection.current.received).to be_an Hash
      expect( IB::Connection.current.received.keys).to include  :Alert
    end

    it "clients are NOT present"  do
      expect{ IB::Connection.current.clients }.to raise_error NoMethodError
    end
    it "can be disconnected" do
      ib =  IB::Connection.current
      expect( ib.ready?  ).to be_truthy
      expect { ib.disconnect! }.to change { ib.workflow_state }.to 'disconnected'
      expect( ib.disconnected?  ).to be_truthy
      expect( ib.ready? ).to be_falsy
    end
  end

  context " load plugins in the fly" do

    it "connection-tools can be loaded in ready state"  do
      ib =  IB::Connection.current
      expect { ib.try_connection! }.to change{ ib.workflow_state }.to 'ready'
      expect( ib.ready? ).to be_truthy
      expect{ ib.check_connection }.to raise_error NoMethodError

      ib.activate_plugin :connection_tools
      expect( ib.check_connection ).to be_truthy
      expect( ib.ready? ).to be_truthy # unchanged


    end


    it "if disconnected, account-based operations can be loaded" do
      ib =  IB::Connection.current
      expect( ib.workflow_state ).to eq 'ready'
      expect { ib.activate_plugin :managed_accounts } .to raise_error Workflow::NoTransitionAllowed
      expect( ib.ready? ).to be_truthy
      expect( ib.plugins ).not_to include "managed-accounts"
      expect { ib.disconnect! }.to change{ ib.workflow_state }.to 'disconnected'
      expect { ib.activate_plugin :managed_accounts } .not_to raise_error
      expect( ib.plugins ).to include "managed-accounts"
      expect { ib.initialize_managed_accounts! }.to change{ ib.workflow_state }.to 'account_based_operations'
      expect( ib.clients ).to be_an Array

    end
  end


end
