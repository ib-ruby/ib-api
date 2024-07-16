module IB
require 'active_support/core_ext/date/calculations'
require 'csv'

=begin

Plugin to support EndOfDay OHLC-Data for a contract

Public API
==========

Extends IB::Contract

* eod

  * request  EndOfDay historical data

  * returns an Array of OHLC-EOD-Records or a Polars-Dataframe populated with OHLC-Records for the contract
    and populates IB::Contract#bars


* get_bars

  * request historical data for custom ohlc-timeframes,

* from_csv and to_csv

  *  store and retrieve ohlc-data


=end

 module Eod
  module BuisinesDays
  # https://stackoverflow.com/questions/4027768/calculate-number-of-business-days-between-two-days

    # Calculates the number of business days in range (start_date, end_date]
    #
    # @param start_date [Date]
    # @param end_date [Date]
    #
    # @return [Fixnum]
    def self.business_days_between(start_date, end_date)
      days_between = (end_date - start_date).to_i
      return 0 unless days_between > 0

                # Assuming we need to calculate days from 9th to 25th, 10-23 are covered
                # by whole weeks, and 24-25 are extra days.
                #
                # Su Mo Tu We Th Fr Sa    # Su Mo Tu We Th Fr Sa
                #        1  2  3  4  5    #        1  2  3  4  5
                #  6  7  8  9 10 11 12    #  6  7  8  9 ww ww ww
                # 13 14 15 16 17 18 19    # ww ww ww ww ww ww ww
                # 20 21 22 23 24 25 26    # ww ww ww ww ed ed 26
                # 27 28 29 30 31          # 27 28 29 30 31
                    whole_weeks, extra_days = days_between.divmod(7)

                    unless extra_days.zero?
                # Extra days start from the week day next to start_day,
                # and end on end_date's week date. The position of the
                # start date in a week can be either before (the left calendar)
                # or after (the right one) the end date.
                #
                # Su Mo Tu We Th Fr Sa    # Su Mo Tu We Th Fr Sa
                #        1  2  3  4  5    #        1  2  3  4  5
                #  6  7  8  9 10 11 12    #  6  7  8  9 10 11 12
                # ## ## ## ## 17 18 19    # 13 14 15 16 ## ## ##
                # 20 21 22 23 24 25 26    # ## 21 22 23 24 25 26
                # 27 28 29 30 31          # 27 28 29 30 31
                #
                # If some of the extra_days fall on a weekend, they need to be subtracted.
                # In the first case only corner days can be days off,
                # and in the second case there are indeed two such days.
                      extra_days -= if start_date.tomorrow.wday <= end_date.wday
                                      [start_date.tomorrow.sunday?, end_date.saturday?].count(true)
                                    else
                                      2
                                    end
                    end

                    (whole_weeks * 5) + extra_days
    end
  end
    # Receive EOD-Data and store the data in the `:bars`-property of IB::Contract
    #
    # contract.eod duration: {String or Integer}, start: {Date}, to: {Date}, what: {see below},  polars: {true|false}
    #
    #
    #
    # The Enddate has to be specified (as Date Object), `:to`,  default: Date.today
    #
    # The Duration can either be a String "yx D", "yd W", "yx M" or an Integer ( implies "D").
    #  *notice*  "W"  fetchtes weekly  and "M" monthly bars
    #
    # A start date can be  given with the `:start` parameter.
    #
    # The parameter `:what` specifies the kind of received data.
    #
    #  Valid values:
    #   :trades, :midpoint, :bid, :ask, :bid_ask,
    #   :historical_volatility, :option_implied_volatility,
    #   :option_volume, :option_open_interest
    #
    # Polars DataFrames
    # -----------------
    # If »polars: true« is specified the response is stored as PolarsDataframe.
    # For further processing: https://github.com/ankane/polars-ruby
    #                         https://pola-rs.github.io/polars/py-polars/html/index.html
    #
    # Error-handling
    # --------------
    # * Basically all Errors simply lead to log-entries:
    # * the contract is not valid,
    # * no market data subscriptions
    # * other servers-side errors
    #
    # If the duration is longer then the maximum range, the response is
    # cut to the maximum allowed range
    #
    # Customize the result
    # --------------------
    # The results are stored in the `:bars` property of the contract
    #
    #
    # Limitations
    # -----------
    # To identify a request, the con_id of the asset is used
    # Thus, parallel requests of a single asset with different time-frames will fail
    #
    # Examples
    # --------
    #
    # puts  Stock.new( symbol: :iwm).eod( start: Date.new(2019,10,9), duration: 3, polars: true)
        # shape: (3, 8)
        # ┌────────────┬────────┬────────┬────────┬────────┬────────┬─────────┬────────┐
        # │ time       ┆ open   ┆ high   ┆ low    ┆ close  ┆ volume ┆ wap     ┆ trades │
        # │ ---        ┆ ---    ┆ ---    ┆ ---    ┆ ---    ┆ ---    ┆ ---     ┆ ---    │
        # │ date       ┆ f64    ┆ f64    ┆ f64    ┆ f64    ┆ i64    ┆ f64     ┆ i64    │
        # ╞════════════╪════════╪════════╪════════╪════════╪════════╪═════════╪════════╡
        # │ 2019-10-08 ┆ 148.62 ┆ 149.37 ┆ 146.11 ┆ 146.45 ┆ 156625 ┆ 146.831 ┆ 88252  │
        # │ 2019-10-09 ┆ 147.18 ┆ 148.0  ┆ 145.38 ┆ 145.85 ┆ 94337  ┆ 147.201 ┆ 51294  │
        # │ 2019-10-10 ┆ 146.9  ┆ 148.74 ┆ 146.87 ┆ 148.24 ┆ 134549 ┆ 147.792 ┆ 71084  │
        # └────────────┴────────┴────────┴────────┴────────┴────────┴─────────┴────────┘
        #
    # puts  Stock.new( symbol: :iwm).eod( start: Date.new(2021,10,9), duration: '3W', polars: true)
        # shape: (3, 8)
        # ┌────────────┬────────┬────────┬────────┬────────┬─────────┬─────────┬────────┐
        # │ time       ┆ open   ┆ high   ┆ low    ┆ close  ┆ volume  ┆ wap     ┆ trades │
        # │ ---        ┆ ---    ┆ ---    ┆ ---    ┆ ---    ┆ ---     ┆ ---     ┆ ---    │
        # │ date       ┆ f64    ┆ f64    ┆ f64    ┆ f64    ┆ i64     ┆ f64     ┆ i64    │
        # ╞════════════╪════════╪════════╪════════╪════════╪═════════╪═════════╪════════╡
        # │ 2021-10-01 ┆ 223.99 ┆ 227.68 ┆ 216.12 ┆ 222.8  ┆ 1295495 ┆ 222.226 ┆ 792711 │
        # │ 2021-10-08 ┆ 221.4  ┆ 224.95 ┆ 216.76 ┆ 221.65 ┆ 1044233 ┆ 220.855 ┆ 621984 │
        # │ 2021-10-15 ┆ 220.69 ┆ 228.41 ┆ 218.94 ┆ 225.05 ┆ 768065  ┆ 223.626 ┆ 437817 │
        # └────────────┴────────┴────────┴────────┴────────┴─────────┴─────────┴────────┘
        #
    # puts  Stock.new( symbol: :iwm).eod( start: Date.new(2022,10,1), duration: '3M', polars: true)
        # shape: (3, 8)
        # ┌────────────┬────────┬────────┬────────┬────────┬─────────┬─────────┬─────────┐
        # │ time       ┆ open   ┆ high   ┆ low    ┆ close  ┆ volume  ┆ wap     ┆ trades  │
        # │ ---        ┆ ---    ┆ ---    ┆ ---    ┆ ---    ┆ ---     ┆ ---     ┆ ---     │
        # │ date       ┆ f64    ┆ f64    ┆ f64    ┆ f64    ┆ i64     ┆ f64     ┆ i64     │
        # ╞════════════╪════════╪════════╪════════╪════════╪═════════╪═════════╪═════════╡
        # │ 2022-09-30 ┆ 181.17 ┆ 191.37 ┆ 162.77 ┆ 165.16 ┆ 4298969 ┆ 175.37  ┆ 2202407 │
        # │ 2022-10-31 ┆ 165.5  ┆ 184.24 ┆ 162.5  ┆ 183.5  ┆ 4740014 ┆ 173.369 ┆ 2474286 │
        # │ 2022-11-30 ┆ 184.51 ┆ 189.56 ┆ 174.11 ┆ 188.19 ┆ 3793861 ┆ 182.594 ┆ 1945674 │
        # └────────────┴────────┴────────┴────────┴────────┴─────────┴─────────┴─────────┘
        #
    # puts  Stock.new( symbol: :iwm).eod( start: Date.new(2020,1,1), duration: '3M', what: :option_implied_vol, polars: true
        # atility )
        # shape: (3, 8)
        # ┌────────────┬──────────┬──────────┬──────────┬──────────┬────────┬──────────┬────────┐
        # │ time       ┆ open     ┆ high     ┆ low      ┆ close    ┆ volume ┆ wap      ┆ trades │
        # │ ---        ┆ ---      ┆ ---      ┆ ---      ┆ ---      ┆ ---    ┆ ---      ┆ ---    │
        # │ date       ┆ f64      ┆ f64      ┆ f64      ┆ f64      ┆ i64    ┆ f64      ┆ i64    │
        # ╞════════════╪══════════╪══════════╪══════════╪══════════╪════════╪══════════╪════════╡
        # │ 2019-12-31 ┆ 0.134933 ┆ 0.177794 ┆ 0.115884 ┆ 0.138108 ┆ 0      ┆ 0.178318 ┆ 0      │
        # │ 2020-01-31 ┆ 0.139696 ┆ 0.190494 ┆ 0.120646 ┆ 0.185732 ┆ 0      ┆ 0.19097  ┆ 0      │
        # │ 2020-02-28 ┆ 0.185732 ┆ 0.436549 ┆ 0.134933 ┆ 0.39845  ┆ 0      ┆ 0.435866 ┆ 0      │
        # └────────────┴──────────┴──────────┴──────────┴──────────┴────────┴──────────┴────────┘
        #
        def eod start: nil, to: nil, duration: nil , what: :trades, polars: false

         # error "EOD:: Start-Date (parameter: to) must be a Date-Object" unless to.is_a? Date
          normalize_duration = ->(d) do
            error "incompatible duration: #{d.class}" unless d.is_a?(Integer) || d.is_a?(String)
            if d.is_a?(Integer) || !["D","M","W","Y"].include?( d[-1].upcase )
              d.to_i.to_s + "D"
            else
              d.gsub(" ","")
            end.insert(-2, " ")
          end

          get_end_date = -> do
            d = normalize_duration.call(duration)
            case  d[-1]
            when "D"
              start + d.to_i - 1
            when 'W'
              Date.commercial( start.year, start.cweek + d.to_i - 1, 1)
            when 'M'
              Date.new( start.year, start.month + d.to_i - 1 , start.day )
            end
          end

          if to.nil?
          #  case   eod start= Date.new ...
            to =   if start.present? && duration.nil?
          # case    eod start= Date.new
                     duration = BuisinesDays.business_days_between(start, Date.today).to_s + "D"
                     Date.today #  assign to var: to
                   elsif start.present? && duration.present?
          # case    eod start= Date.new , duration: 'nN'
                     get_end_date.call  # assign to var: to
                   elsif duration.present?
          # case    start is not present, we are collecting until the present day
                      Date.today         # assign to var: to
                   else
                     duration =  "1D"
                     Date.today
                   end
          end
          if duration.nil?
            duration = BuisinesDays.business_days_between(start, to)
          end

          barsize = case normalize_duration.call(duration)[-1].upcase
                    when "W"
                      :week1
                    when "M"
                      :month1
                    else
                      :day1
                    end


         get_bars(to.to_time.to_ib , normalize_duration[duration], barsize, what, polars)

        end # def

    # creates (or overwrites) the specified file (or symbol.csv) and saves bar-data
    def to_csv file: "#{symbol}.csv"
      if bars.present?
        headers = bars.first.invariant_attributes.keys
        CSV.open( file, 'w' ) {|f| f << headers ; bars.each {|y| f << y.invariant_attributes.values } }
      end
    end

    # read csv-data into bars
    def from_csv file: nil
      file ||=  "#{symbol}.csv"
      self.bars = []
      CSV.foreach( file,  headers: true, header_converters: :symbol) do |row|
        self.bars << IB::Bar.new( **row.to_h )
      end
    end

    def get_bars(end_date_time, duration, bar_size, what_to_show, polars)

      tws = IB::Connection.current
      received =  Queue.new
      r = nil
      # the hole response is transmitted at once!
      a = tws.subscribe(IB::Messages::Incoming::HistoricalData) do |msg|
        if msg.request_id == con_id
          self.bars = if polars
                        # msg.results.each { |entry| puts "  #{entry}" }
                        Polars::DataFrame.new  msg.results.map( &:invariant_attributes )
                      else
                        msg.results
                      end
        end
        received.push Time.now
      end
      b = tws.subscribe( IB::Messages::Incoming::Alert) do  |msg|
        if [321,162,200].include? msg.code
          tws.logger.info msg.message
          # TWS Error 200: No security definition has been found for the request
          # TWS Error 354: Requested market data is not subscribed.
          # TWS Error 162  # Historical Market Data Service error
          received.close
        elsif msg.code.to_i == 2174
          tws.logger.info "Please switch to the \"10-19\"-Branch of the git-repository"
        end
      end


      tws.send_message IB::Messages::Outgoing::RequestHistoricalData.new(
        :request_id => con_id,
        :contract =>  self,
        :end_date_time => end_date_time,
        :duration => duration, # see ib/messages/outgoing/bar_request.rb => max duration for 5sec bar lookback is 10 000 - i.e. will yield 2000 bars
        :bar_size =>  bar_size, #  IB::BAR_SIZES.key(:hour)
        :what_to_show => what_to_show,
        :use_rth => 0,
        :format_date => 2,
        :keep_up_todate => 0)

      received.pop # blocks until a message is ready on the queue or the queue is closed

      tws.unsubscribe a
      tws.unsubscribe b

      block_given? ?  bars.map{|y| yield y} : bars  # return bars or result of block

    end # def
  end # module eod

  class Contract
    include Eod
  end  # class
end # module IB

