# ib-api
Ruby interface to Interactive Brokers' TWS API 

Reimplementation of the basic functions if ib-ruby into a small gem


`ib-api`   offers a modular access to the TWS-Api-Interface of Interactive Brokers.

In its plain vanilla usage, it just exchanges messages with the TWS. The User is responsible for any further data processing.

Additional services can be loaded via `require` 

* require 'symbols'  enables the usage of predefined Symbols and Watchlists
* require 'order-prototypes' enables to use predefined orders like: `Limit.order`, `SimpleStop.order` etc
* require 'spread-prototypes' offers a simple method to define popular spreads 
* require 'extensions/verify' adds a handy `verify` method to Contract
* require 'extensions/market-price' simplifies the fetching of the actual market_price to any instrument
* require 'extensions/eod' fetches _end of Day_ historical data from any instrument
* require 'extensions/option-chain' gives easy access to atm, otm and itm-Option-chains



(in progress)




## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/core. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## Code of Conduct

Everyone interacting in the Core project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/core/blob/master/CODE_OF_CONDUCT.md).
