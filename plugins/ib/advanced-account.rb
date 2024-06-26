module IB
=begin

Plugin that provides helper methods for orders


Public API
==========

Extends IB::Account

=end

  module Advanced


    def account_data_scan search_key, search_currency=nil
        if search_currency.present?
          account_values.find_all{|x| x.key.match( search_key )  && x.currency == search_currency.upcase }
        else
          account_values.find_all{|x| x.key.match( search_key ) }
        end
    end



=begin rdoc
given any key of local_id, perm_id or order_ref
and an optional status, which can be a string or a
regexp ( status: /mitted/ matches Submitted and Presubmitted)
the last associated Order-record is returned.

Thus if several Orders are placed with the same order_ref, the active one is returned

(If multible keys are specified, local_id preceeds perm_id)

=end
	def locate_order local_id: nil, perm_id: nil, order_ref: nil, status: /ubmitted/, contract: nil, con_id: nil
		search_option = [ local_id.present? ? [:local_id , local_id] : nil ,
							perm_id.present? ? [:perm_id, perm_id] : nil,
							order_ref.present? ? [:order_ref , order_ref ] : nil ].compact.first
		matched_items = if search_option.nil?
							orders  # select all orders of the current account
						else
              key,value = search_option
							orders.find_all{|x| x[key].to_i == value.to_i }
            end

      if contract.present?
        if contract.con_id.zero?  && !contract.is_a?( IB::Bag )
          contract =  contract.verify.first
        end
        matched_items = matched_items.find_all{|o| o.contract.essential == contract.essential }
      elsif con_id.present?
        matched_items = matched_items.find_all{|o| o.contract.con_id == con_id }
      end

      if status.present?
        status = Regexp.new(status) unless status.is_a? Regexp
        matched_items.detect{|x| x.order_state.status =~ status }
      else
        matched_items.last  # return the last item
      end
    end


=begin rdoc
requires an IB::Order as parameter.

If attached, the associated IB::Contract is used to specify the tws-command

The associated Contract overtakes  the specified (as parameter)

auto_adjust: Limit- and Aux-Prices are adjusted to Min-Tick

convert_size: The action-attribute (:buy  :sell) is associated according the content of :total_quantity.


The parameter «order» is modified!

It can further used to modify and eventually cancel


Example

   j36 =  IB::Stock.new symbol: 'J36', exchange: 'SGX'
   order =  IB::Limit.order size: 100, price: 65.5
   g =  IB::Gateway.current.clients.last

   g.preview contract: j36, order: order
      => {:init_margin=>0.10864874e6,
          :maint_margin=>0.9704137e5,
          :equity_with_loan=>0.97877973e6,
          :commission=>0.524e1,
          :commission_currency=>"USD",
          :warning=>""

   the_local_id = g.place order: order
      => 67						# returns local_id
   order.contract			# updated contract-record

      => #<IB::Contract:0x00000000013c94b0 @attributes={:con_id=>9534669,
                                                        :exchange=>"SGX",
                                                        :right=>"",
                                                        :include_expired=>false}>

   order.limit_price = 65   # set new price
   g.modify order: order    # and transmit
     => 67 # returns local_id

   g.locate_order( local_id: the_local_id  )
     => returns the assigned order-record for inspection

    g.cancel order: order
    # logger output: 05:17:11 Cancelling 65 New #250/ from 3000/DU167349>
=end

  def place_order  order:, contract: nil, auto_adjust: true, convert_size: true
    # adjust the order price to  min-tick
    result = ->(l){ orders.detect{|x| x.local_id == l  && x.submitted? } }
    qualified_contract = ->(c) do
       c.is_a?(IB::Contract) &&
    #·IB::Symbols are always qualified. They carry a description-field
         ( c.description.present? || !c.con_id.to_i.zero? ||
          (c.con_id.to_i <0  && c.sec_type == :bag ) )   # bags that carry a negative con_id are qualified
    end

    # assign qualificated contract to the order object if not present
    order.contract ||= if qualified_contract[ contract ]
                         contract
                       else
                         contract.verify.first
                       end

    error "No valid contract given" unless order.contract.is_a?(IB::Contract)

    ## sending of plain vanilla IB::Bags will fail using account.place, unless a (negative) con-id is provided!
    error "place order: ContractVerification failed. No con_id assigned"  unless qualified_contract[order.contract]

    # declare some variables
    ib = IB::Connection.current
    wrong_order = nil
    the_local_id =  nil
    q =  Queue.new

    ### Handle Error messages
    ### Default action:  raise IB::Transmission Error
    sa = ib.subscribe( :Alert ) do | msg |
      if msg.error_id == the_local_id
        if [ 110, #  The price does not confirm to the minimum price variation for this contract
            201, # Order rejected, No Trading permissions
            203, # Security is not allowed for trading
            325, # Discretionary Orders are not supported for this combination of order-type and exchange
            355, # Order size does not conform to market rule
            361, 362, 363, 364, # invalid trigger or stop-price
            388,  # Order size x is smaller than the minimum required size of yy.
        ].include? msg.code
          wrong_order =  msg.message
          ib.logger.error msg.message
          q.close   # closing the queue indicates that no order was transmitted
        end
      end
    end
    # transfer the received openOrder to the queue
    sb = ib.subscribe( :OpenOrder ){|m| q << m.order if m.order.local_id.to_i == the_local_id.to_i }
    #  modify order (parameter)
    order.account =  account  # assign the account_id to the account-field of IB::Order
    self.orders.save_insert order, :order_ref
    order.auto_adjust  if respond_to?( :auto_adjust ) && auto_adjust # /defined in  file order_handling.rb
    if convert_size
      order.action = order.total_quantity.to_i < 0 ? :sell : :buy unless order.action == :sell
      logger.info{ "Converted ordersize to #{order.total_quantity} and triggered a #{order.action}  order"} if  order.total_quantity.to_i < 0
      order.total_quantity  = order.total_quantity.to_i.abs
    end
    # apply non_guarenteed and other stuff bound to the contract to order.
    order.attributes.merge! order.contract.order_requirements unless order.contract.order_requirements.blank?
    #  con_id and exchange fully qualify a contract, no need to transmit other data
    #  if no contract is passed to order.place, order.contract is used for placement
    the_contract = order.contract.con_id.to_i > 0 ? Contract.new( con_id: order.contract.con_id, exchange: order.contract.exchange) : nil
    the_local_id = order.place the_contract # return the local_id
    # if transmit is false, just include the local_id in the order-record
    Thread.new{  if order.transmit  || order.what_if  then sleep 1 else sleep 0.001 end ;  q.close }
    tws_answer = q.pop

    ib.unsubscribe sa
    ib.unsubscribe sb
    if q.closed?
      if wrong_order.present?
        raise IB::SymbolError,  wrong_order
      elsif the_local_id.present?
        order.local_id = the_local_id
      else
      error " #{order.to_human} is not transmitted properly", :symbol
      end
    else
      order=tws_answer #  return order-record received from tws
    end
    the_local_id  # return_value
  end # place


  # shortcut to enable
  #  account.place order: {} , contract: {}
  #  account.preview order: {} , contract: {}
  #  account.modify order: {}
  alias place place_order

=begin #rdoc
Account#ModifyOrder operates in two modi:

First: The order is specified  via local_id, perm_id or order_ref.
  It is checked, whether the order is still modifyable.
  Then the Order ist provided through  the block. Any modification is done there.
  Important: The Block has to return the modified IB::Order

Second: The order can be provided as parameter as well. This will be used
without further checking. The block is now optional.
  Important: The OrderRecord must provide a valid Contract.

The simple version does not adjust the given prices to tick-limits.
This has to be done manually in the provided block
=end


		def modify_order  local_id: nil, order_ref: nil, order:nil

			result = ->(l){ orders.detect{|x| x.local_id == l  && x.submitted? } }
			order ||= locate_order( local_id: local_id,
														 status: /ubmitted/ ,
														 order_ref: order_ref )
			if order.is_a? IB::Order
				order.modify
			else
				error "No suitable IB::Order provided/detected. Instead: #{order.inspect}"
			end
		end

		alias modify modify_order

# Preview
		#
		# Submits a "WhatIf" Order
		#
		# Returns the order_state.forecast
		#
		# The order received from the TWS is kept in account.orders
		#
		# Raises IB::SymbolError if the Order could not be placed properly
		#
	def preview order:, contract: nil, **args_which_are_ignored
		# to_do:  use a copy of order instead of temporary setting order.what_if
    q =  Queue.new
    ib =  IB::Connection.current
    the_local_id = nil
    # put the order into the queue (and exit) if the event is fired
    req =  ib.subscribe( :OpenOrder ){|m| q << m.order if m.order.local_id.to_i == the_local_id.to_i }

    order.what_if = true
    order.account = account
    the_local_id = order.place  contract
    Thread.new{  sleep 2  ;  q.close }   #  wait max 2 sec.
    returned_order = q.pop
    ib.unsubscribe req
    order.what_if = false # reset what_if flag
    order.local_id = nil  # reset local_id to enable re-using the order-object for placing
    raise IB::SymbolError,"(Preview-) #{order.to_human} is not transmitted properly" if q.closed?
    returned_order.order_state.forcast  #  return_value
  end

# closes the contract by submitting an appropriate order
	# the action- and total_amount attributes of the assigned order are overwritten.
	#
	# if a ratio-value (0 ..1) is specified in _order.total_quantity_ only a fraction of the position is closed.
	# Other values are silently ignored
	#
	# if _reverse_ is specified, the opposite position is established.
	# Any value in total_quantity is overwritten
	#
	# returns the order transmitted
	#
	# raises an IB::Error if no PortfolioValues have been loaded to the IB::Account
	def close order:, contract: nil, reverse: false,  **args_which_are_ignored
		error "must only be called after initializing portfolio_values "  if portfolio_values.blank?
		contract_size = ->(c) do			# note: portfolio_value.position is either positiv or negativ
			if c.con_id <0 # Spread
				p = portfolio_values.detect{|p| p.contract.con_id ==c.legs.first.con_id} &.position.to_i
				p/ c.combo_legs.first.weight  unless p.to_i.zero?
			else
				portfolio_values.detect{|x| x.contract.con_id == c.con_id} &.position.to_i   # nil.to_i -->0
			end
		end

    order.contract =  contract.verify.first unless contract.nil?
		error "Cannot transmit the order – No Contract given " unless order.contract.is_a?( IB::Contract )

		the_quantity = if reverse
						 -contract_size[order.contract] * 2
					 elsif order.total_quantity.abs < 1 && !order.total_quantity.zero?
						-contract_size[order.contract] *  order.total_quantity.abs
					 else
						-contract_size[order.contract]
					 end
		if the_quantity.zero?
			logger.info{ "Cannot close #{order.contract.to_human} - no position detected"}
		else
			order.total_quantity = the_quantity
			order.action =  nil
			order.local_id =  nil  # in any case, close is a new order
			logger.info { "Order modified to close, reduce or revese position: #{order.to_human}" }
			place order: order, convert_size: true
		end
	end

# just a wrapper to the Gateway-cancel-order method
	def cancel order:
		Connection.current.cancel_order order
	end

  ## ToDo ... needs adaption !
	#returns an hash where portfolio_positions are grouped into Watchlists.
	#
	# Watchlist => [  contract => [ portfoliopositon] , ... ] ]
	#
  def organize_portfolio_positions   the_watchlistsi #= IB::Gateway.current.active_watchlists
		  the_watchlists = [ the_watchlists ] unless the_watchlists.is_a?(Array)
			self.focuses = portfolio_values.map do | pw |             # iterate over pw
                     ref_con_id = pw.contract.con_id
							                z =	the_watchlists.map do | w |           # iterate over w and assign to z
                                  watchlist_contract = w.find do |c|      # iterate over c
								                                        if c.is_a? IB::Bag
                                                           c.combo_legs.map( &:con_id ).include?( ref_con_id )
                                                        else
                                                           c.con_id == ref_con_id
                                                         end
                                                       end rescue nil
                                  watchlist_contract.present? ? [w,watchlist_contract] : nil
                               end.compact

										z.empty? ? [ IB::Symbols::Unspecified, pw.contract, pw ] : z.first + pw
			end.group_by{|a,_,_| a }.map{|x,y|[x, y.map{|_,d,e|[d,e]}.group_by{|e,_| e}.map{|f,z| [f, z.map(&:last)]} ] }.to_h
			# group:by --> [a,b,c] .group_by {|_g,_| g} --->{ a => [a,b,c] }
			# group_by+map --> removes "a" from the resulting array
		end


		def locate_contract con_id
			contracts.detect{|x| x.con_id.to_i == con_id.to_i }
		end

		## returns the contract definition of an complex portfolio-position detected in the account
		def complex_position con_id
			con_id = con_id.con_id	if con_id.is_a?(IB::Contract)
			focuses.map{|x,y| y.detect{|x,y| x.con_id.to_i==  con_id.to_i} }.compact.flatten.first
		end
	end # module  Advanced
		##
		# in the console   (call gateway with watchlist: [:Spreads, :BuyAndHold])
#head :001 > .clients.first.focuses.to_a.to_human
#Unspecified
#<Stock: BLUE EUR SBF>
#<PortfolioValue: DU167348 Pos=720 @ 15.88;Value=11433.24;PNL=-4870.05 unrealized;<Stock: BLUE EUR SBF>
#<Stock: CSCO USD NASDAQ>
#<PortfolioValue: DU167348 Pos=44 @ 44.4;Value=1953.6;PNL=1009.8 unrealized;<Stock: CSCO USD NASDAQ>
#<Stock: DBB USD ARCA>
#<PortfolioValue: DU167348 Pos=-1 @ 16.575;Value=-16.58;PNL=1.05 unrealized;<Stock: DBB USD ARCA>
#<Stock: NEU USD NYSE>
#<PortfolioValue: DU167348 Pos=1 @ 375.617;Value=375.62;PNL=98.63 unrealized;<Stock: NEU USD NYSE>
#<Stock: WFC USD NYSE>
#<PortfolioValue: DU167348 Pos=100 @ 51.25;Value=5125.0;PNL=-171.0 unrealized;<Stock: WFC USD NYSE>
#BuyAndHold
#<Stock: CIEN USD NYSE>
#<PortfolioValue: DU167348 Pos=812 @ 29.637;Value=24065.57;PNL=4841.47 unrealized;<Stock: CIEN USD NYSE>
#<Stock: J36 USD SGX>
#<PortfolioValue: DU167348 Pos=100 @ 56.245;Value=5624.5;PNL=-830.66 unrealized;<Stock: J36 USD SGX>
#Spreads
#<Strangle Estx50(3200.0,3000.0)[Dec 2018]>
#<PortfolioValue: DU167348 Pos=-3 @ 168.933;Value=-5067.99;PNL=603.51 unrealized;<Option: ESTX50 20181221 call 3000.0  EUR>
#<PortfolioValue: DU167348 Pos=-3 @ 142.574;Value=-4277.22;PNL=-867.72 unrealized;<Option: ESTX50 20181221 put 3200.0  EUR>
# => nil
#		#

class Account 
   include Advanced
end
end ## module IB
