# ib-api
Ruby interface to Interactive Brokers' TWS API 

Reimplementation of the basic functions of ib-ruby


----
`ib-ruby`   offers a modular access to the TWS-API-Interface of Interactive Brokers.

`ib-api`    provides a simple interface to low-level TWS API-calls.  

----

Install in the usual way

```
$ gem install ib-api
```

In its plain vanilla usage, it just exchanges messages with the TWS. Any response is stored in the `recieved-Array`.

Even then, it needs just a few lines of code to place an order

```ruby
require 'ib-api'
# connect with default parameters 
ib =  IB::Connection.new 

# define a contract to deal with
the_stock =  IB::Stock.new symbol: 'TAP'

# order 100 shares for 35 $ 
limit_order = IB::Order.new  limit_price: 35, order_type: 'LMT',  total_quantity: 100, action: :buy
ib.send_message :PlaceOrder,
        :order => limit_order,
        :contract => the_stock,
        :local_id => ib.next_local_id

# wait until the orderstate message returned
ib.wait_for :OrderStatus

# print the Orderstatus
puts ib.recieved[:OrderStatus].to_human

# => ["<OrderState: Submitted #17/1528367295 from 2000 filled 0.0/100.0 at 0.0/0.0 why_held >"]

```

##### User-specific Actions
Besides storing any TWS-response in an array, callbacks are implemented.

The user subscribes to a certain response and defines the actions in a typically ruby manner. These actions
can be defined globaly
```ruby
ib =  IB::Connection.new do |tws|
      # Subscribe to TWS alerts/errors and order-related messages
	tws.subscribe(:Alert, :OpenOrder, :OrderStatus, :OpenOrderEnd) { |msg| puts msg.to_human }
     end

```

or occationally

```ruby
        # first define actions
	a = ib.subscribe(:Alert, :ContractData ) do |msg| 
		case msg
		when Messages::Incoming::Alert
			if msg.code == 200   # No security found 
				# do someting
			end
		when Messages::Incoming::ContractData  # security returned
			# do something
	
		end  # case
	end
        # perform request
        ib.send_message :RequestContractData, :contract => #{some contract}
         
        # wait until the :ContractDataEnd message returned
        ib.wait_for :ContractDataEnd
         
        ib.unsubscribe a    # release subscriptions
         
```
## Minimal TWS-Version

`ib-api` is tested via the _stable IB-Gateway_ (Version 9.72) and should work with any current tws-installation. 

## Tests

are invoked by 

```
bundle exec guard
# or
bundle exec rake spec
```
Integration tests on order-placements are not included. To run the test suite its thus safe to use a _real Account_.
You have to edit `spec/spec.yml` and replace the `:account`-Setting with your own `AccountID`, even if you connect to a single account. 
 

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/ib-api. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## Code of Conduct

Everyone interacting in the Core project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/ib-api/blob/master/CODE_OF_CONDUCT.md).
