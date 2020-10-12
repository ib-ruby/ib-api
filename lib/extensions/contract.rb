
	def associate_ticdata

		tws=  IB::Gateway.tws 		 # get the initialized ib-ruby instance
		the_id =  nil
		finalize= false
		#  switch to delayed data
		tws.send_message :RequestMarketDataType, :market_data_type => :delayed

		s_id = tws.subscribe(:TickSnapshotEnd) { |msg|	finalize = true	if msg.ticker_id == the_id }
				
		sub_id = tws.subscribe(:TickPrice, :TickSize,  :TickGeneric, :TickOption) do |msg|
			    self.bars << msg.the_data if msg.ticker_id == the_id 
			end

		# initialize »the_id« that is used to identify the received tick messages
		# by firing the market data request
		the_id = tws.send_message :RequestMarketData,  contract: self , snapshot: true 

		#keep the method-call running until the request finished
		#and cancel subscriptions to the message handler.
		Thread.new do 
                  i=0; loop{ i+=1; sleep 0.1; break if finalize || i > 1000 }
                  tws.unsubscribe sub_id 
                  tws.unsubscribe s_id
                  puts "#{symbol} data gathered" 
                end  # method returns the (running) thread

	end # def 
######################  private methods 

		end # class




end # module
