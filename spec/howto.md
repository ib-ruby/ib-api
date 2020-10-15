How to Implement and Test IB::Messages
========================================

* Implement a Request-Message in lib/ib/messages/outgoing.rb 
  or the /lib/ib/messages/outgoing/ directory

* Implement a Response-Message in lib/ib/messages/incoming.rb
  or the /lib/ib/messages/incoming directory


* Fire the Request-Message and watch die Response
  * uncomment row 37  in lib/ib/messages/incoming/abstract_message.rb
			### DEBUG  DEBUG  DEBUG  RAW STREAM                            ###############
			#  if uncommented, the raw-input from the tws is included in the logging
			#			puts "BUFFER .> #{buffer.inspect}"
			### DEBUG  DEBUG  DEBUG  RAW STREAM                            ###############

			Then the Rresponse from the TWS is printed on STDOUT

  
  Testcode
  ```
	ib = IB::Connection.current 
	ib.send_message :RequestHistogramData,  contract: {some IB::Contract}
											 time_period: '1 week', 
  ib.wait_for :HistogramData  
  ```

	The Message:id and (if provided) Version are stripped from the output
	In case of the former request

	> BUFFER :> ["2", "-1", "2106", "HMDS data farm connection is OK:ushmds"] 
	> BUFFER .> ["119", "74", "7.07", "143", "6.56", "19120", "6.65", "73982", "6.81", "263800", "6.9", "98011",  ...

	In this case fhe first item is the request_id, followed by the count of datapoints, as defined in 
	lib/ib/messages/incoming/histrorical_data.rb

	```
		HistogramData  = def_message( [89,0], 
																	[:request_id, :int], 
																	[ :number_of_points , :int ]
	```
	The data-points are read through the _load_ method of the class, which stores them in _@results_

* Debugging
  The received date are collected in IB::Connection.received 
	```
	 subject { @ib.received[:HistogramData].first }

	```
  assignes the first collected dataset of :HistogramData to the test-facility

	Not processed items remain in the :buffer of each recieved messages. 

	* Debugging in the Console

	If a test fails or a new Message Type is implemented, the console can be used to quick check

	```
./console t

>> IB-Core Interactive Console <<
---------------------------------------------

Namespace is IB ! 

---------------------------------------------
Connected to server, version: 137,
 connection time: 2020-10-15 10:10:12 +0000 local, 2020-10-15T10:10:11+00:00 remote.
< ManagedAccounts: U1274612>
Got next valid order id: 1.
Connection established on Port  7496, client_id 2000 used

----> C    points to the connection-instance


 > contract =  IB::Stock.new symbol: 'GE'
 > C.send_message :RequestHistogramData,  contract: contract,  time_period: '1 week'
 => 5072     ## -> used request_id
 > C.received.keys
 => [:ManagedAccounts, :NextValidId, :Alert, :OpenOrder, :HistogramData] 

 > C.received[C.received.keys.last].to_human
 => ["<HistogramData: 5072, 74 read>"]
 > C.received[C.received.keys.last].last.results.map{|y| y[:count].to_i}
 => [143, 19120, 73982, 263800, 98011, 11023, 4871, 42990, 306147, 895, 19915, 110774, 22586, 126706, 6096, 83490, 149932, 21311, 35524, 6944, 65087, 232369, 9576, 35159, 122290, 45887, 795, 112962, 78903, 5966, 1808, 19005, 93166, 324220, 35500, 99738, 122790, 16814, 65385, 17812, 10502, 13341, 62210, 157568, 173461, 7756, 18981, 9371, 113317, 5607, 7852, 22367, 143653, 26114, 32768, 10015, 83643, 19093, 42325, 141890, 75655, 18985, 13078, 96357, 5308, 3525, 38467, 57274, 48712, 256365, 1884, 39927, 27638, 2481] 
> C.received[C.received.keys.last].last.results.map{|y| y[:price].to_f}
 => [7.07, 6.56, 6.65, 6.81, 6.9, 6.4, 7.06, 6.57, 6.82, 7.01, 6.51, 6.76, 6.5, 6.75, 7.0, 6.72, 6.8, 6.97, 6.55, 6.47, 6.59, 6.84, 6.37, 6.62, 6.87, 7.05, 6.34, 6.77, 6.52, 6.46, 7.02, 6.96, 6.71, 6.83, 6.64, 6.89, 6.58, 6.39, 6.92, 6.67, 6.36, 6.42, 6.61, 6.86, 6.79, 6.48, 6.54, 6.98, 6.73, 7.04, 7.03, 6.63, 6.88, 6.38, 6.66, 6.45, 6.91, 6.95, 6.53, 6.78, 6.7, 6.41, 6.49, 6.74, 6.99, 6.43, 6.68, 6.93, 6.6, 6.85, 6.44, 6.69, 6.94, 6.35]

		```

