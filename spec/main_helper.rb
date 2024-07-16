require 'spec_helper'
require 'thread'
require 'stringio'
require 'rspec/expectations'

## Logger helpers

def mock_logger
  @stdout = StringIO.new

  @logger = Logger.new(@stdout).tap do |logger|
    logger.formatter = proc do |level, time, prog, msg|
      "#{time.strftime('%H:%M:%S')} #{msg}\n"
    end
    logger.level = Logger::INFO
  end
end

def log_entries
  @stdout && @stdout.string.split(/\n/)
end


def should_log *patterns
  patterns.each do |pattern|
   expect( log_entries.any? { |entry| entry =~ pattern }).to be_truthy
  end
end

def should_not_log *patterns
  patterns.each do |pattern|
    expect( log_entries.any? { |entry| entry =~ pattern }).to be_falsey
  end
end


## Connection helpers
def establish_connection *plugins
  ib =  nil
  accounts = nil
  if plugins.map( &:to_s ).include?("managed-accounts") || plugins.include?("process-orders") || plugins.include?('gateway')
      OPTS[:connection].merge connect: false
       ib = IB::Connection.new **OPTS[:connection].merge(:logger => mock_logger)
       ib.activate_plugin 'verify', 'process-orders', 'advanced-account'
       ib.received = true
       ib.get_account_data
       ib.request_open_orders
       accounts = ib.clients.map(&:account)

  else
      ib = IB::Connection.new **OPTS[:connection].merge(:logger => mock_logger)
      ib.received = true
      ib.try_connection!
      ib.wait_for :ManagedAccounts, 5

      raise "Unable to verify IB PAPER ACCOUNT" unless ib.received?(:ManagedAccounts)

      accounts = ib.received[:ManagedAccounts].first.accounts_list.split(',')
  end
  if ib
      unless accounts.include?(ACCOUNT)
        close_connection
        raise "Connected to wrong account ! Expected #{ACCOUNT} to be included in  #{accounts},  \n edit \'spec/config.yml\' " 
      end
      puts "Performing tests with ClientId: #{ib.client_id}"
      OPTS[:account_verified] = true
  else
      OPTS[:account_verified] =  false
      raise "could not establish connection!"
  end
end




# Clear logs and message collector. Output may be silenced.
def clean_connection
  ib =  IB::Connection.current
  if ib
    if OPTS[:verbose]
      puts ib.received.map { |type, msg| [" #{type}:", msg.map(&:to_human)] }
      puts " Logs:", log_entries if @stdout
    end
    @stdout.string = '' if @stdout
    ib.clear_received
  end
end

def close_connection
  clean_connection
  IB::Connection.current.disconnect! unless IB::Connection.current.workflow_state == 'disconnected'
end
