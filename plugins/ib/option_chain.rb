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
      sub_sdop = ib.subscribe(:SecurityDefinitionOptionParameterEnd) do |msg|
        finalize.close if msg.request_id == my_req
      end
      sub_ocd = ib.subscribe(:OptionChainDefinition) do |msg|
        finalize.push(msg.data) if msg.request_id == my_req
      end

      contract = verify.first  #  ensure a complete set of attributes
      my_req = ib.send_message :RequestOptionChainDefinition,
                               con_id: contract.con_id,
                               symbol: contract.symbol,
                               exchange: contract.sec_type == :future ? contract.exchange : "", # BOX,CBOE',
                               trading_class:,
                               sec_type: contract[:sec_type]

      until finalize.closed?
        @option_chain_definition << finalize.pop
      end
      ib.unsubscribe sub_sdop, sub_ocd
    else
      Connection.logger.info { "#{to_human} : using cached data" }
    end

    @option_chain_definition.compact!
    Connection.logger.info { @option_chain_definition.map { |x| x.slice(:trading_class, :exchange)} }
    @option_chain_definition = @option_chain_definition.find { |x| (trading_class.blank? || x[:trading_class] == trading_class) && (exchange.blank? || x[:exchange] == exchange) } ||
                               @option_chain_definition.find { |x| x[:exchange] == contract.exchange && x[:trading_class] == contract.trading_class } ||
                               @option_chain_definition.find { |x| x[:exchange] == 'SMART' } ||
                               @option_chain_definition.first

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
      requested_expiration = @option_chain_definition[:expirations]
        .select { |expiration| monthly_expiration?(expiration) }
      Connection.logger.info @option_chain_definition.inspect

      if sort == :strike
        options_by_strike(requested_strikes, requested_expiration, right)
      else
        options_by_expiry(requested_strikes, requested_expiration, right)
      end
    else
      Connection.logger.error "#{to_human} ::No Options available"
      nil # return_value
    end
  end  # def

  # return a set of AtTheMoneyOptions
  def atm_options(ref_price: :request, right: :put, **params)
    option_chain(right:, ref_price:, sort: :expiry, **params) do |chain|
      chain[0]
    end
  end

  # return InTheMoneyOptions
  def itm_options(count: 5, right: :put, ref_price: :request, sort: :strike, **params)
    option_chain(right:, ref_price:, sort:, **params) do |chain|
      if right == :put
        chain[1][0..count-1] # above market price
      else
        chain[-1][-count..-1].reverse # below market price
      end
    end
  end

  # return OutOfTheMoneyOptions
  def otm_options(count: 5, right: :put, ref_price: :request, sort: :strike, **params)
    option_chain(right:, ref_price:, sort:, **params ) do |chain|
      if right == :put
        chain[-1][-count..-1].reverse # below market price
      else
        chain[1][0..count-1] # above market price
      end
    end
  end

  private

  def option_prototype(last_trading_day, strike, right)
    IB::Option.new(
      symbol:,
      exchange: @option_chain_definition[:exchange],
      trading_class: @option_chain_definition[:trading_class],
      multiplier: @option_chain_definition[:multiplier],
      currency: currency,
      last_trading_day:,
      strike:,
      right:
    ).verify &.first
  end

  def options_by_expiry(strikes, expirations, right)
    # Array: [ yymm -> Options] prepares for the correct conversion to a Hash
    expirations.map do |expiration_date|
      [
        expiration_date.strftime('%Y-%m-%d'),
        strikes.map { |strike| option_prototype(expiration_date, strike, right) }.compact
      ]
    end.to_h
  end

  def options_by_strike(strikes, expirations, right)
    strikes.map do |strike|
      [
        strike,
        expirations.map { |expiration_date| option_prototype(expiration_date, strike, right) }.compact
      ]
    end.to_h
  end

  def monthly_expiration?(last_trading_day)
    first_day_of_month = last_trading_day.beginning_of_month
    third_friday = first_day_of_month.advance(days: ((5 - first_day_of_month.wday) % 7), weeks: 2)

    last_trading_day == third_friday
  end
 end # module

 Connection.current.activate_plugin 'verify'
 Connection.current.activate_plugin 'market_price'

 class Contract
   include OptionChain
 end

end # module
