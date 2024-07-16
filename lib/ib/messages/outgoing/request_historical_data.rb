module IB
  module Messages
    module Outgoing
      extend Messages # def_message macros


      RequestHistoricalData = def_message [20, 0], BarRequestMessage,
        :request_id  # autogenerated if not specified

      # - data = {
      #          :contract => Contract: requested ticker description
      #          :end_date_time => String: "yyyymmdd HH:mm:ss", with optional time zone
      #                            allowed after a space: "20050701 18:26:44 GMT"
      #          :duration => String, time span the request will cover, and is specified
      #                  using the format: <integer> <unit>, eg: '1 D', valid units are:
      #                        '1 S' (seconds, default if no unit is specified)
      #                        '1 D' (days)
      #                        '1 W' (weeks)
      #                        '1 M' (months)
      #                        '1 Y' (years, currently limited to one)
      #          :bar_size => String: Specifies the size of the bars that will be returned
      #                       (within IB/TWS limits). Valid values include:
      #                             '1 sec'
      #                             '5 secs'
      #                             '15 secs'
      #                             '30 secs'
      #                             '1 min'
      #                             '2 mins'
      #                             '3 mins'
      #                             '5 mins'
      #                             '15 mins'
      #                             '30 min'
      #                             '1 hour'
      #                             '1 day'
      #          :what_to_show => Symbol: Determines the nature of data being extracted.
      #                           Valid values:
      #                             :trades, :midpoint, :bid, :ask, :bid_ask,
      #                             :historical_volatility, :option_implied_volatility,
      #                             :option_volume, :option_open_interest
      #                              - converts to "TRADES," "MIDPOINT," "BID," etc...
      #          :use_rth => int: 0 - all data available during the time span requested
      #                     is returned, even data bars covering time intervals where the
      #                     market in question was illiquid. 1 - only data within the
      #                     "Regular Trading Hours" of the product in question is returned,
      #                     even if the time span requested falls partially or completely
      #                     outside of them.
      #          :format_date => int: 1 - text format, like "20050307 11:32:16".
      #                               2 - offset from 1970-01-01 in sec (UNIX epoch)
      #         }
      #
      # - NB: using the D :duration only returns bars in whole days, so requesting "1 D"
      #   for contract ending at 08:05 will only return 1 bar, for 08:00 on that day.
      #   But requesting "86400 S" gives 86400/barlengthsecs bars before the end Time.
      #
      # - Note also that the :duration for any request must be such that the start Time is not
      #   more than one year before the CURRENT-Time-less-one-day (not 1 year before the end
      #   Time in the Request)
      #
      #     Bar Size Max Duration
      #     -------- ------------
      #      1 sec        2000 S
      #      5 sec       10000 S
      #      15 sec      30000 S
      #      30 sec      86400 S
      #      1 minute    86400 S, 6 D
      #      2 minutes   86400 S, 6 D
      #      5 minutes   86400 S, 6 D
      #      15 minutes  86400 S, 6 D, 20 D, 2 W
      #      30 minutes  86400 S, 34 D, 4 W, 1 M
      #      1 hour      86400 S, 34 D, 4 w, 1 M
      #      1 day       60 D, 12 M, 52 W, 1 Y
      #  
      # - NB: as of 4/07 there is no historical data available for forex spot.
      #
      # - data[:contract] may either be a Contract object or a String. A String should be
      #   in serialize_ib_ruby format; that is, it should be a colon-delimited string in
      #   the format (e.g. for Globex British pound futures contract expiring in Sep-2008):
      #
      #
      # - Fields not needed for a particular security should be left blank (e.g. strike
      #   and right are only relevant for options.)
      #
      # - A Contract object will be automatically serialized into the required format.
      #
      # - See also http://chuckcaplan.com/twsapi/index.php/void%20reqIntradayData%28%29
      #   for general information about how TWS handles historic data requests, whence
      #   the following has been adapted:
      #
      # - The server providing historical prices appears to not always be
      #   available outside of market hours. If you call it outside of its
      #   supported time period, or if there is otherwise a problem with
      #   it, you will receive error #162 "Historical Market Data Service
      #   query failed.:HMDS query returned no data."
      #
      # - For backfill on futures data, you may need to leave the Primary
      #   Exchange field of the Contract structure blank; see
      #   http://www.interactivebrokers.com/discus/messages/2/28477.html?1114646754
      #
      # - Version 6 implemented --> the version is not transmitted anymore
      class RequestHistoricalData
        def parse data
          data_type, bar_size, contract = super data

          size = data[:bar_size] || data[:size]
          bar_size = BAR_SIZES.invert[size] || size
          unless  BAR_SIZES.keys.include?(bar_size)
            error ":bar_size must be one of #{BAR_SIZES.inspect}", :args
          end
          [data_type, bar_size, contract]
        end

        def encode
          data_type, bar_size, contract = parse @data

          [super.flatten,
           contract.serialize_long[0..-1],   # omit sec_id_type and sec_id
           @data[:end_date_time],
           bar_size,
           @data[:duration],
           @data[:use_rth],
           data_type.to_s.upcase,
          2 , # @data[:format_date], format-date is hard-coded as int_date in incoming/historicalData 
           contract.serialize_legs ,
     @data[:keep_up_todate],   # 0 / 1
    ''  #  chartOptions:TagValueList - For internal use only. Use default value XYZ.  
    ]
        end
      end # RequestHistoricalData

    end # module Outgoing
  end # module Messages
end # module IB

## python documentaion
#   """Requests contracts' historical data. When requesting historical data, a
#        finishing time and date is required along with a duration string. The
#        resulting bars will be returned in EWrapper.historicalData()
#        reqId:TickerId - The id of the request. Must be a unique value. When the
#            market data returns, it whatToShowill be identified by this tag. This is also
#            used when canceling the market data.
#        contract:Contract - This object contains a description of the contract for which
#            market data is being requested.
#        endDateTime:str - Defines a query end date and time at any point during the past 6 mos.
#            Valid values include any date/time within the past six months in the format:
#            yyyymmdd HH:mm:ss ttt
#            where "ttt" is the optional time zone.
#        durationStr:str - Set the query duration up to one week, using a time unit
#            of seconds, days or weeks. Valid values include any integer followed by a space
#            and then S (seconds), D (days) or W (week). If no unit is specified, seconds is used.
#        barSizeSetting:str - Specifies the size of the bars that will be returned (within IB/TWS listimits).
#            Valid values include:
#            1 sec
#            5 secs
#            15 secs
#            30 secs
#            1 min
#            2 mins
#            3 mins
#            5 mins
#            15 mins
#            30 mins
#            1 hour
#            1 day
#        whatToShow:str - Determines the nature of data beinging extracted. Valid values include:
#            TRADES
#            MIDPOINT
#            BID
#            ASK
#            BID_ASK
#            HISTORICAL_VOLATILITY
#            OPTION_IMPLIED_VOLATILITY
#        useRTH:int - Determines whether to return all data available during the requested time span,
#            or only data that falls within regular trading hours. Valid values include:
#            0 - all data is returned even where the market in question was outside of its
#            regular trading hours.
#            1 - only data within the regular trading hours is returned, even if the
#            requested time span falls partially or completely outside of the RTH.
#        formatDate: int - Determines the date format applied to returned bars. validd values include:
#            1 - dates applying to bars returned in the format: yyyymmdd{space}{space}hh:mm:dd
#            2 - dates are returned as a long integer specifying the number of seconds since
#                1/1/1970 GMT.
#        chartOptions:TagValueList - For internal use only. Use default value XYZ. """
