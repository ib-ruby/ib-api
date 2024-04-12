# ib-api
Ruby interface to Interactive Brokers' TWS API 

Reimplementation of the basic functions of ib-ruby

---
__STATUS: Placement of orders is currently broken__

---


__Documentation: [https://ib-ruby.github.io/ib-doc/](https://ib-ruby.github.io/ib-doc/)__  (_work in progress_)

----
`ib-api`   offers a modular access to the TWS-API-Interface of Interactive Brokers.

----

Install in the usual way

```
$ gem install ib-api
```

In its plain vanilla usage, it just exchanges messages with the TWS. Any response is stored in the `received-Array`.

It needs just a few lines of code to place an order

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

## Plugins

**IB-API** ships with simple plugins to facilitate automations 

```ruby
require 'ib-api'
# connect with default parameters 
ib =  IB::Connection.new do | c |
  c.activate_plugin "verify"
end

g =  IB::Stock.new symbol: 'GE'
puts g.verify.first.attributes
{:symbol=>"GE", :sec_type=>"STK", :last_trading_day=>"", :strike=>0.0, :right=>"", :exchange=>"SMART", :currency=>"USD", :local_symbol=>"GE", :trading_class=>"GE", :con_id=>498843743, :multiplier=>0, :primary_exchange=>"NYSE", }
```

Currently implemented plugins

* connection-tools: ensure that a connection is established and active
* verify:  get contract details from the tws
* managed-accounts: fetch and organize account- and portfoliovalues
* market-price: fetch the current market-price of a contract
* eod:  retrieve EOD-Data for the given contract
* greeks: read current option greeks
* option-chain: build option-chains for given strikes and expiries 
* spread-prototypes:  create limit, stop, market, etc. orders through prototypes
* probability-of-expiring: calculate the probability of expiring for the option-contract


## Minimal TWS-Version

`ib-api` is tested via the _stable IB-Gateway_ (Version 10.19) and should work with any current tws-installation. 

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

Bug reports and pull requests are welcome. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## Code of Conduct

Everyone interacting in the Core project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/ib-api/blob/master/CODE_OF_CONDUCT.md).
