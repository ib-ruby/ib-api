module IB
  module Messages
    module Outgoing
      extend Messages # def_message macros
      # Start receiving market scanner results through the ScannerData messages.
      # @data = { :id => ticker_id (int),
      #  :number_of_rows => int: number of rows of data to return for a query.
      #  :instrument => The instrument type for the scan. Values include
      #                                'STK', - US stocks
      #                                'STOCK.HK' - Asian stocks
      #                                'STOCK.EU' - European stocks
      #  :location_code => Legal Values include:
      #                           - STK.US - US stocks
      #                           - STK.US.MAJOR - US stocks (without pink sheet)
      #                           - STK.US.MINOR - US stocks (only pink sheet)
      #                           - STK.HK.SEHK - Hong Kong stocks
      #                           - STK.HK.ASX - Australian Stocks
      #                           - STK.EU - European stocks
      #  :scan_code => The type of the scan, such as HIGH_OPT_VOLUME_PUT_CALL_RATIO.
      #  :above_price => double: Only contracts with a price above this value.
      #  :below_price => double: Only contracts with a price below this value.
      #  :above_volume => int: Only contracts with a volume above this value.
      #  :market_cap_above => double: Only contracts with a market cap above this
      #  :market_cap_below => double: Only contracts with a market cap below this value.
      #  :moody_rating_above => Only contracts with a Moody rating above this value.
      #  :moody_rating_below => Only contracts with a Moody rating below this value.
      #  :sp_rating_above => Only contracts with an S&P rating above this value.
      #  :sp_rating_below => Only contracts with an S&P rating below this value.
      #  :maturity_date_above => Only contracts with a maturity date later than this
      #  :maturity_date_below => Only contracts with a maturity date earlier than this
      #  :coupon_rate_above => double: Only contracts with a coupon rate above this
      #  :coupon_rate_below => double: Only contracts with a coupon rate below this
      #  :exclude_convertible => Exclude convertible bonds.
      #  :scanner_setting_pairs => Used with the scan_code to help further narrow your query.
      #                            Scanner Setting Pairs are delimited by slashes, making
      #                            this parameter open ended. Example is "Annual,true" -
      #                            when used with 'Top Option Implied Vol % Gainers' scan
      #                            would return annualized volatilities.
      #  :average_option_volume_above =>  int: Only contracts with average volume above this
      #  :stock_type_filter => Valid values are:
      #                          'ALL' (excludes nothing)
      #                          'STOCK' (excludes ETFs)
      #                          'ETF' (includes ETFs) }
      # ------------
      # To learn all valid parameter values that a scanner subscription can have,
      # first subscribe to ScannerParameters and send RequestScannerParameters message.
      # Available scanner parameters values will be listed in received XML document.
      RequestScannerSubscription =
          def_message([22, 3], :request_id , 
                      [:number_of_rows, -1], # was: EOL,
                      :instrument,
                      :location_code,
                      :scan_code,
                      :above_price,
                      :below_price,
                      :above_volume,
                      :market_cap_above,
                      :market_cap_below,
                      :moody_rating_above,
                      :moody_rating_below,
                      :sp_rating_above,
                      :sp_rating_below,
                      :maturity_date_above,
                      :maturity_date_below,
                      :coupon_rate_above,
                      :coupon_rate_below,
                      :exclude_convertible,
                      :average_option_volume_above, # ?
                      :scanner_setting_pairs,
                      :stock_type_filter)
    end
  end
end
