module IB
 module Greeks

# Ask for the Greeks and implied Vola
#
# The result can be customized by a provided block.
#
#	IB::Symbols::Options.aapl.greeks{ |x| x }
#	-> {"bid"=>0.10142e3, "ask"=>0.10144e3, "last"=>0.10142e3, "close"=>0.10172e3}
#
#   Possible values for Parameter :what --> :all :model, :bid, :ask, :bidask, :last
#
	 def request_greeks delayed:  true, what: :model, thread: false

		 tws = Connection.current 		 # get the initialized ib-ruby instance
		 # define requested tick-attributes
		 request_data_type = IB::MARKET_DATA_TYPES.rassoc( delayed ? :frozen_delayed : :frozen ).first
		 # possible types = 	[ [ :delayed_model_option , :model_option ] , [:delayed_last_option , :last_option ],
		 # [ :delayed_bid_option , :bid_option ], [ :delayed_ask_option , :ask_option ]]
		 tws.send_message :RequestMarketDataType, :market_data_type =>  request_data_type
		 tickdata = []

		 self.greek = OptionDetail.new if greek.nil?
     greek.updated_at = Time.now
     greek.option = self
     queue =  Queue.new

		 #keep the method-call running until the request finished
		 #and cancel subscriptions to the message handler
		 # method returns the (running) thread
		 th = Thread.new do
			 the_id  =  nil
			 # subscribe to TickPrices
       s_id = tws.subscribe(:TickSnapshotEnd) { |msg|	queue.push(true)	if msg.ticker_id == the_id  }
       e_id = tws.subscribe(:Alert){|x| queue.push(false)  if [200,353].include?( x.code) && x.error_id == the_id }
       t_id = tws.subscribe( :TickSnapshotEnd, :TickPrice, :TickString, :TickSize, :TickGeneric, :MarketDataType, :TickRequestParameters  ) {|msg| msg }
			 # TWS Error 200: No security definition has been found for the request
			 # TWS Error 354: Requested market data is not subscribed.

			 sub_id = tws.subscribe(:TickOption ) do |msg| #, :TickSize,  :TickGeneric  do |msg|
				 if  msg.ticker_id == the_id # && tickdata.is_a?(Array) # do nothing if tickdata have already gathered
					 case msg.type
					 when /ask/
						 greek.ask_price = msg.option_price unless msg.option_price.nil?
						 tickdata << msg  if [ :all, :ask, :bidask ].include?( what	)

					 when /bid/
						 greek.bid_price = msg.option_price unless msg.option_price.nil?
						 tickdata << msg  if [ :all, :bid, :bidask ].include?( what	)
					 when /last/
						 tickdata << msg  if msg.type =~ /last/
					 when /model/
						 #  transfer attributs from TickOption to OptionDetail
						 bf =[ :option_price, :implied_volatility, :under_price, :pv_dividend ]
						 (bf + msg.greeks.keys).each{ |a| greek.send( a.to_s+"=", msg.send( a)) }
						 tickdata << msg  if [ :all, :model ].include?( what	)
					 end
           # fast entry abortion ---> daiabled for now
         #  queue.push(true) if tickdata.is_a?(IB::Messages::Incoming::TickOption) || (tickdata.size == 2 && what== :bidask) || (tickdata.size == 4 && what == :all)
				 end
			 end  # if sub_id

			 # initialize »the_id« that is used to identify the received tick messages
			 # by firing the market data request
       iji = 0
       loop do
         the_id = tws.send_message :RequestMarketData,  contract: self , snapshot: true

         result = queue.pop
         # reduce :close_price delayed_close  to close a.s.o
         if result == false
           Connection.logger.info{ "#{to_human} --> No Marketdata received " }
         else
           self.misc =  tickdata if thread  # store internally if in thread modus
         end
         break if  !tickdata.empty?  ||  iji > 10
         iji =  iji + 1
         Connection.logger.info{ "OptionGreeks::#{to_human} --> delayed processing. Trying again (#{iji}) " }
       end
			 tws.unsubscribe sub_id, s_id, e_id, t_id
		 end  # thread
		 if thread
			 th		# return thread
		 else
			 th.join
       greek
		 end
   end
 end
 class Option
   include Greeks
 end
end
