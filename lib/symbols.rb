# These modules are used to facilitate referencing of most popular IB Contracts.
# Like pages in the TWS-GUI, theya can be utilised to organise trading and research.
#
# Symbol Allocations are organized as modules. They represent the contents of yaml files in
#
#		ib-ruby-root/lib/symbols/
#
#	Any collection is represented as simple Hash, with  __key__ as qualifier and an __IB::Contract__ as value.
#	The Value is either a fully prequalified Contract  (Stock, Option, Future, Forex, CFD, BAG) or
#	a lazy qualified Contract acting as base für further calucaltions and requests.
#
#		IB::Symbols.allocate_collection :Name
#
# creates the Module and file. If a previously created file is found, its contents are read and
# the vcollection ist reestablished.
#
#		IB::Symbols::Name.add_contract :wfc, IB::Stock.new( symbol: 'WFC' )
#
#	adds the contract and stores it in the yaml file
#
#	  IB::Symbols::Name.wfc   # or  IB::Symbols::Name[:wfc]
#
#	retrieves the contract
#
#		IB::Symbols::Name.all 
#
#	returns an Array of stored contracts
#
#		IB::Symbols::Name.remove_contract :wfc
#
# deletes the contract from the list (and the file)
#
# To finish the cycle
#
#		IB::Symbols::Name.purge_collection
#
#	deletes the file and erases the collection in memory.
#
#	Additional methods can be introduced 
#		* for individual contracts on the module-level or
#		* to organize the list as methods of Array in  Module IB::SymbolExtention
#
#
# Contracts can be hardcoded in the required standard-collections as well.
# Note that the :description field is local to ib-ruby, and is NOT part of the standard TWS API.
# It is never transmitted to IB. It's purely used clientside, and you can store any arbitrary
# string that you may find useful there.

require_relative 'ib/symbols_base'
require_relative 'ib/symbols/forex'
require_relative 'ib/symbols/futures'
require_relative 'ib/symbols/stocks'
require_relative 'ib/symbols/index'
require_relative 'ib/symbols/cfd'
require_relative 'ib/symbols/commodity'
require_relative 'ib/symbols/options'
require_relative 'ib/symbols/combo'
require_relative 'ib/symbols/bonds'
require_relative 'ib/symbols/abstract'
