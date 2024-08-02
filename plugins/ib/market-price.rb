module IB

 module MarketPrice
   # Ask for the Market-Price
   #
   # For valid contracts, either bid/ask or last_price and close_price are transmitted.
   #
   # If last_price is received, its returned.
   # If not, midpoint (bid+ask/2) is used. Else the closing price will be returned.
   #
   # Any  value (even 0.0) which is stored in IB::Contract.misc indicates that the contract is
   # accepted by `request_market_data` and will be accepted by `place_order`, too.
   #
   # The result can be customized by a provided block.
   #
   # ```ruby
   # IB::Symbols::Stocks.sie.market_price{ |x| x }
   # -> {"bid"=>0.10142e3, "ask"=>0.10144e3, "last"=>0.10142e3, "close"=>0.10172e3}
   # ```
   #
   #
   # Raw-data are stored in the _bars_-property of IB::Contract
   # (volatile, ie. data are not preserved when the Object is reused via Contract#merge)
   #
   # ```ruby
   #  u= (z1=IB::Stock.new(symbol: :ge)).market_price
   #  A: Requested market data is not subscribed. Displaying delayed market data.
   #  > u  => 0.16975e3
   #  > z1 => #<IB::Stock:0x00007f91037f0e18
   #         @attributes= { :symbol =>"ge", (...)
   #                      :currency => "USD",
   #                      :exchange => "SMART" },
   #         @bars = [ { last: -0.1e1, close: 0.16975e3, bid: -0.1e1, ask: -0.1e1 } ],
   #         @misc = { delayed: 0.16975e3 }
   #
   # ```
   #
   # Fetching of market-data is a time consuming process. A threaded approach is suitable
   # to get a bunch of market-data in time
   #
   # ```ruby
   #  th  = (z2 = IB::Stock.new(symbol: :ge)).market_price(thread: true)
   #  th.join
   # ```
   # assigns z2.misc with the value of the :last (or delayed_last) TickPrice-Message
   # and returns the thread.
   #

   def market_price delayed:  true, thread: false, no_error: false

     tws=  Connection.current    # get the initialized ib-ruby instance
     the_id , the_price =  nil, nil
     tickdata =  Hash.new
     q =  Queue.new
     # define requested tick-attributes
     last, close, bid, ask   =  [ [ :delayed_last , :last_price ] , [:delayed_close , :close_price ],
                                 [  :delayed_bid , :bid_price ], [  :delayed_ask , :ask_price ]]
     request_data_type = delayed ? :frozen_delayed :  :frozen

     # From the tws-documentation (https://interactivebrokers.github.io/tws-api/market_data_type.html)
     # Beginning in TWS v970, a IBApi.EClient.reqMarketDataType callback of 1 will occur automatically
     # after invoking reqMktData if the user has live data permissions for the instrument.
     #
     # so - even if "delayed" is specified, realtime-data are returned if RT-permissions are present
     #

     # method returns the (running) thread
     th = Thread.new do
       # about 11 sec after the request, the TWS returns :TickSnapshotEnd if no ticks are transmitted
       # we don't have to implement our own timeout-criteria
       s_id = tws.subscribe(:TickSnapshotEnd){|x| q.push(true) if x.ticker_id == the_id }
       a_id = tws.subscribe(:Alert){|x| q.push(x) if [200, 354, 10167, 10168].include?( x.code )  && x.error_id == the_id }
       # TWS Error 354: Requested market data is not subscribed.

       # subscribe to TickPrices
       sub_id = tws.subscribe(:TickPrice ) do |msg| #, :TickSize,  :TickGeneric, :TickOption) do |msg|
         [last,close,bid,ask].each do |x|
           tickdata[x] = msg.the_data[:price] if x.include?( IB::TICK_TYPES[ msg.the_data[:tick_type]])
           #  fast exit condition
           q.push(true) if tickdata.size >= 4
         end if  msg.ticker_id == the_id
       end
       # initialize »the_id« that is used to identify the received tick messages
       # by firing the market data request
       the_id = tws.send_message :RequestMarketData,  contract: self , snapshot: true

       while !q.closed? do
         result = q.pop
         if result.is_a? IB::Messages::Incoming::Alert
           tws.logger.debug result.message
           case result.code
           when 200
             q.close
             error "#{to_human} --> #{result.message}"   unless no_error
           when 354, #   not subscribed to market data
             10167,
             10168
             if delayed && !(result.message =~ /market data is not available/)
               tws.logger.debug  "#{to_human} --> requesting delayed data"
               tws.send_message :RequestMarketDataType, :market_data_type => 3
               self.misc = :delayed
               sleep 0.1
               the_id = tws.send_message :RequestMarketData,  contract: self , snapshot: true
             else
               q.close
               tws.logger.error "#{to_human} --> No marketdata permissions"  unless no_error
             end
           end
         elsif result.present?
           q.close
           tz = -> (z){ z.map{|y| y.to_s.split('_')}.flatten.count_duplicates.max_by{|k,v| v}.first.to_sym}
           data =  tickdata.map{|x,y| [tz[x],y]}.to_h
           valid_data = ->(d){ !(d.to_i.zero? || d.to_i == -1) }
           self.bars << data                      #  store raw data in bars
           the_price = if block_given?
                         yield data
                         # yields {:bid=>0.10142e3, :ask=>0.10144e3, :last=>0.10142e3, :close=>0.10172e3}
                       else # behavior if no block is provided
                         if valid_data[data[:last]]
                           data[:last]
                         elsif valid_data[data[:bid]]
                           (data[:bid]+data[:ask])/2
                         elsif data[:close].present?
                           data[:close]
                         else
                           nil
                         end
                       end

           self.misc = misc == :delayed ? { :delayed =>  the_price }  : { realtime: the_price }
         else
           q.close
           error "#{to_human} --> No Marketdata received "
         end
       end

       tws.unsubscribe sub_id, s_id, a_id
     end
     if thread
       th # return thread
     else
       th.join
       the_price  # return
     end
   end #
 end
 class Contract
   include MarketPrice
 end
end
