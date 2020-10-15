# ib-api
Ruby interface to Interactive Brokers' TWS API 

Reimplementation of the basic functions if ib-ruby into a small gem

**Status:** The code is under final rewiew. A Gem will be release shortly.

`ib-api`   offers a modular access to the TWS-Api-Interface of Interactive Brokers.

In its plain vanilla usage, it just exchanges messages with the TWS. The User is responsible for any further data processing.

It needs just a few lines of code to place an order

```ruby
# connect 
ib =  IB::Connection.new 

# define a contract to deal with
the_stock =  IB::Stock.new symbol: 'TAP'

# order 100 stocks for 35 $ 
limit_order = Order.new  limit_price: 35, order_type: 'LMT',  total_quantity: 100, action: :buy
ib.place_order limit_order, the_stock

# wait until the orderstate message returned
ib.wait_for :OrderStatus

# print the Orderstatus
puts ib.recieved[:OrderStatus].to_human

# => ["<OrderState: Submitted #17/1528367295 from 2000 filled 0.0/100.0 at 0.0/0.0 why_held >"]

```





## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/ib-api. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## Code of Conduct

Everyone interacting in the Core project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/ib-api/blob/master/CODE_OF_CONDUCT.md).
