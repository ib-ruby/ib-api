module IB

 module OptionChain

  # returns the Option Chain  (monthly options, expiry: third friday)
  # of the contract (if available)
  #
  #
  ## parameters
  ### right:: :call, :put, :straddle                ( default: :put )
  ### ref_price::  :request or a numeric value      ( default:  :request )
  ### sort:: :strike, :expiry
  ### exchange:: List of Exchanges to be queried (Blank for all available Exchanges)
  ### trading_class                                 ( optional )
  def option_chain ref_price: :request, right: :put, sort: :strike, exchange: '', trading_class: nil

    ib = Connection.current

    # binary interthread communication
    finalize = Queue.new

    ## Enable Cashing of Definition-Matrix
    @option_chain_definition ||= []

    my_req = nil

    # -----------------------------------------------------------------------------------------------------
    # get OptionChainDefinition from IB ( instantiate cashed Hash )
    if @option_chain_definition.blank?
      sub_sdop = ib.subscribe( :SecurityDefinitionOptionParameterEnd ) { |msg| finalize.push(true) if msg.request_id == my_req }
      sub_ocd = ib.subscribe( :OptionChainDefinition ) do | msg |
        if msg.request_id == my_req
          message = msg.data
          # transfer the first record to @option_chain_definition
          if @option_chain_definition.blank?
            @option_chain_definition = msg.data
          end
          # override @option_chain_definition if a decent combination of attributes is met
          # us- options:  use the smart dataset
          # other options: prefer options of the default trading class
          if message[:exchange] == 'SMART'
            @option_chain_definition = msg.data
            finalize.push(true)
          end
          if message[:trading_class] == symbol
            @option_chain_definition = msg.data
            finalize.push(true)
          end
        end
      end

      c = verify.first  #  ensure a complete set of attributes
      my_req = ib.send_message :RequestOptionChainDefinition, con_id: c.con_id,
        symbol: c.symbol,
        exchange: c.sec_type == :future ? c.exchange : "", # BOX,CBOE',
        sec_type: c[:sec_type]

      finalize.pop #  wait until data appeared

      ib.unsubscribe sub_sdop, sub_ocd
    else
      Connection.logger.info { "#{to_human} : using cached data" }
    end

    # -----------------------------------------------------------------------------------------------------
    # select values and assign to options
    #
    unless @option_chain_definition.blank?
      requested_strikes = if block_given?
                             ref_price = market_price if ref_price == :request
                             if ref_price.nil?
                               ref_price = @option_chain_definition[:strikes].min +
                                 ( @option_chain_definition[:strikes].max -
                                  @option_chain_definition[:strikes].min ) / 2
                               Connection.logger.warn { "#{to_human} :: market price not set – using midpoint of available strikes instead: #{ref_price.to_f}" }
                             end
                             atm_strike = @option_chain_definition[:strikes].min_by { |x| (x - ref_price).abs }
                             the_grouped_strikes = @option_chain_definition[:strikes].group_by{|e| e <=> atm_strike}
                             begin
                               the_strikes = yield the_grouped_strikes
                               the_strikes.unshift atm_strike unless the_strikes.first == atm_strike	  # the first item is the atm-strike
                               the_strikes
                             rescue
                               Connection.logger.error "#{to_human} :: not enough strikes :#{@option_chain_definition[:strikes].map(&:to_f).join(',')} "
                               []
                             end
                           else
                             @option_chain_definition[:strikes]
                           end

      # third Friday of a month
      monthly_expirations = @option_chain_definition[:expirations].find_all {|y| (15..21).include? y.day }
      #				puts @option_chain_definition.inspect
      option_prototype = -> ( ltd, strike ) do
        IB::Option.new( symbol: symbol,
          exchange: @option_chain_definition[:exchange],
          trading_class: @option_chain_definition[:trading_class],
          multiplier: @option_chain_definition[:multiplier],
          currency: currency,
          last_trading_day: ltd,
          strike: strike,
          right: right).verify &.first
      end
      options_by_expiry = -> ( schema ) do
        # Array: [ yymm -> Options] prepares for the correct conversion to a Hash
        Hash[  monthly_expirations.map do | l_t_d |
          [  l_t_d.strftime('%y%m').to_i , schema.map { | strike | option_prototype[ l_t_d, strike ]}.compact ]
        end  ]                         # by Hash[ ]
      end
      options_by_strike = -> ( schema ) do
        Hash[ schema.map do | strike |
          [  strike ,   monthly_expirations.map { | l_t_d | option_prototype[ l_t_d, strike ]}.compact ]
        end  ]                         # by Hash[ ]
      end

      if sort == :strike
        options_by_strike[ requested_strikes ]
      else
        options_by_expiry[ requested_strikes ]
      end
    else
      Connection.logger.error "#{to_human} ::No Options available"
      nil # return_value
    end
  end  # def

  # return a set of AtTheMoneyOptions
  def atm_options ref_price: :request, right: :put, **params
    option_chain(  right: right, ref_price: ref_price, sort: :expiry, **params) do | chain |
      chain[0]
    end


  end

  # return   InTheMoneyOptions
  def itm_options count:  5, right: :put, ref_price: :request, sort: :strike, exchange: ''
    option_chain(  right: right,  ref_price: ref_price, sort: sort, exchange: exchange ) do | chain |
      if right == :put
        above_market_price_strikes = chain[1][0..count-1]
      else
        below_market_price_strikes = chain[-1][-count..-1].reverse
      end # branch
    end
  end		# def

  # return OutOfTheMoneyOptions
  def otm_options count:  5,  right: :put, ref_price: :request, sort: :strike, exchange: ''
    option_chain( right: right, ref_price: ref_price, sort: sort, exchange: exchange ) do | chain |
      if right == :put
        #			puts "Chain: #{chain}"
        below_market_price_strikes = chain[-1][-count..-1].reverse
      else
        above_market_price_strikes = chain[1][0..count-1]
      end
    end
  end
 end # module

 Connection.current.activate_plugin 'verify'
 Connection.current.activate_plugin 'market-price'

 class Contract
   include OptionChain
 end

end # module
