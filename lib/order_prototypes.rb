#The Module OrderPrototypes provides a wrapper to define even complex ordertypes.
#
#The Order is build by 
#
#	IB::<OrderPrototye>.order
#
#A description is available through
#
#	puts IB::<OrderPrototype>.summary
#
#Nessesary and optional arguments are printed by
#
#	puts IB::<OrderPrototype>.parameters
#
#Orders can be setup interactively
#
#		> d =  Discretionary.order
#		Traceback (most recent call last): (..)
#		IB::ArgumentError (IB::Discretionary.order -> A necessary field is missing: 
#					action: --> {"B"=>:buy, "S"=>:sell, "T"=>:short, "X"=>:short_exempt})
#		> d =  Discretionary.order action: :buy
#		IB::ArgumentError (IB::Discretionary.order -> A necessary field is missing: 
#					total_quantity: --> also aliased as :size)
#		> d =  Discretionary.order action: :buy, size: 100
#					Traceback (most recent call last):
#		IB::ArgumentError (IB::Discretionary.order -> A necessary field is missing: limit_price: --> decimal)
#
#
#
#Prototypes are defined as module. They extend OrderPrototype and establish singleton methods, which
#can adress and extend similar methods from OrderPrototype. 
#
#

require 'ib/order_prototypes/abstract'
require 'ib/order_prototypes/forex'
require 'ib/order_prototypes/market'
require 'ib/order_prototypes/limit'
require 'ib/order_prototypes/stop'
require 'ib/order_prototypes/volatility'
require 'ib/order_prototypes/premarket'
require 'ib/order_prototypes/pegged'
require 'ib/order_prototypes/combo'
