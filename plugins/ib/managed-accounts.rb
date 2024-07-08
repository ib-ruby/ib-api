module IB

=begin

Plugin for Managed Accounts

Provides `clients` and `advisor` objects (Type: IB::Account) that contain account-specific data.

Public Api
==========

* InitializeManagedAccounts
 *  populates @accounts through RequestFA
 *  should be called instead of  `connect`


* GetAccountData
 * requests account- and portfolio-data and associates them to the clients

* provides
   * client.account_values
   * client.portfolio_values
   * client.contracts


The plugin should be activated **before** the connection attempt.

**IB::Connection.current.initialize_manage_acounts performs a `connect` to the tws-server**`


Standard usage

  ib = Connection.new connect: false do | c |
   c.activate_plugin 'managed-accounts'
   c.initialize_managed_accounts             #  connects to the tws
   c.get_account_data                        #  populates c.clients
  end

  account = ib.clients.first
  puts account.portfolio_values.as_table

=end

module ManagedAccounts

=begin
--------------------------- InitializeManageAccounts ----------------------------------

If initiated with the parameter `force: true`, a reconnect is performed to initiate the
transmission of available managed-accounts.

=end
		def initialize_managed_accounts( force: false )
     queue =  Queue.new
     # in case of advisor-accounts:  proper initialiastion of account records
			rec_id = subscribe( :ReceiveFA )  do |msg|
				msg.accounts.each do |a|
					account_data( a.account ){| the_account | the_account.update_attribute :alias, a.alias } unless a.alias.blank?
				end
				logger.info { "Accounts initialized \n #{@accounts.map( &:to_human  ).join " \n " }" }
        queue.push(true)
			end

      # initialisation of Account after a successful connection
			man_id = subscribe( :ManagedAccounts ) do |msg|
        @accounts =  msg.accounts
        send_message( :RequestFA, fa_data_type: 3)
      end

      # single accounts return an alert message
      error_id =  subscribe( :Alert ){|x| queue.push(false) if x.code == 321 }
      @accounts = []

      if connected?
        disconnect!
        sleep(0.1)
      end
      try_connection!
      result = queue.pop
      unsubscribe man_id, rec_id, error_id

      @accounts

		end # def

=begin
clients returns a list of Account-Objects

If only one Account is present,  Client and Advisor are identical.
=end
    def  clients
      @accounts.find_all &:user?
    end

# is the account a financial advisor
    def fa?
      !(advisor == clients.first)
    end


=begin
 The Advisor is always the first account
=end
     def advisor
       @accounts.first
     end


=begin
--------------------------- GetAccountData --------------------------------------------
Queries for Account- and PortfolioValues
The parameter can either be the account_id, the IB::Account-Object or
an Array of account_id and IB::Account-Objects.

Resets Account#portfolio_values and -account_values

Raises an IB::TransmissionError if the account-data are not transmitted in time (1 sec)

Raises an IB::Error if less then 100 items are received.
=end
  def get_account_data  *accounts, **compatibily_argument

		subscription = subscribe_account_updates( continuously: false )
    download_end = nil  # declare variable
    received_array_status = received
    self.received = false

		accounts = clients if accounts.empty?
    logger.warn{ "No active account present. AccountData are NOT requested" } if accounts.empty?
		# Account-infos have to be requested sequentially.
		# subsequent (parallel) calls kill the former on the tws-server-side
		# In addition, there is no need to cancel the subscription of an request, as a new
		# one overwrites the active one.
		accounts.each do | ac |
			account =  ac.is_a?( IB::Account ) ?  ac  : clients.find{|x| x.account == ac }
			error( "No Account detected " )  unless account.is_a? IB::Account
			# don't repeat the query until 170 sec. have passed since the previous update
			if account.last_updated.nil?  || ( Time.now - account.last_updated ) > 170 # sec
        logger.debug{ "#{account.account} :: Erasing Account- and Portfolio Data " }
        logger.debug{ "#{account.account} :: Requesting AccountData " }

        q =  Queue.new
        download_end = subscribe( :AccountDownloadEnd )  do | msg |
          q.push true if msg.account_name == account.account
        end
				# reset account and portfolio-values
				account.portfolio_values = []
				account.account_values = []
        # Data are gathered asynchron through the active subscription defined in  `subscribe_account_updates`
				send_message :RequestAccountData, subscribe: true, account_code: account.account

        th =  Thread.new{   sleep 10 ; q.close  }  # close the queue after 10 seconds
        q.pop                                      # wait for the data (or the closing event)

        if q.closed?
          error "No AccountData received", :reader
        else
          q.close
          unsubscribe download_end
        end

#        account.organize_portfolio_positions  unless IB::Gateway.current.active_watchlists.empty?
			else
        logger.info{ "#{account.account} :: Using stored AccountData " }
			end
		end
    send_message :RequestAccountData, subscribe: false  ## do this only once
    unsubscribe subscription

    self.received = received_array_status
  rescue IB::TransmissionError => e
        unsubscribe download_end unless download_end.nil?
        unsubscribe subscription
        raise
	end


  def all_contracts
		clients.map(&:contracts).flat_map(&:itself).uniq(&:con_id)
  end


	private

	# The subscription method should called only once per session.
	# It places subscribers to AccountValue and PortfolioValue Messages, which should remain
	# active through the session.
  #
  # The method returns the subscription-number.
  #
  # thus
  #    subscription =  subscribe_account_updates
  #    #  some code
  #    IB::Connection.current.unsubscribe subscription
  #
  # clears the subscription
	#

	def subscribe_account_updates continuously: true
		subscribe( :AccountValue, :PortfolioValue,:AccountDownloadEnd )  do | msg |
			account_data( msg.account_name ) do | account |   # enter mutex controlled zone
				case msg
				when IB::Messages::Incoming::AccountValue
					account.account_values << msg.account_value
					account.update_attribute :last_updated, Time.now
          IB::Connection.logger.debug { "#{account.account} :: #{msg.account_value.to_human }"}
				when IB::Messages::Incoming::AccountDownloadEnd
					if account.account_values.size > 10
							# simply don't cancel the subscription if continuously is specified
							# the connected flag is set in any case, indicating that valid data are present
  #          send_message :RequestAccountData, subscribe: false, account_code: account.account unless continuously
						account.update_attribute :connected, true   ## flag: Account is completely initialized
            IB::Connection.logger.info { "#{account.account} => Count of AccountValues: #{account.account_values.size}"  }
					else # unreasonable account_data received -  request is still active
						error  "#{account.account} => Count of AccountValues too small: #{account.account_values.size}" , :reader
					end
				when IB::Messages::Incoming::PortfolioValue
          account.contracts << msg.contract unless account.contracts.detect{|y| y.con_id == msg.contract.con_id }
          account.portfolio_values << msg.portfolio_value
#						msg.portfolio_value.account = account
#           # link contract -> portfolio value
#						account.contracts.find{ |x| x.con_id == msg.contract.con_id }
#								.portfolio_values
#								.update_or_create( msg.portfolio_value ) { :account }
          IB::Connection.logger.debug { "#{ account.account } :: #{ msg.contract.to_human }" }
        end # case
			end # account_data
		end # subscribe
	end  # def

  alias activate_managed_accounts subscribe_account_updates


  end

  class Connection
    include ManagedAccounts
    current.activate_managed_accounts!
  end
end
