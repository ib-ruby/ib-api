# Option contracts definitions.
# TODO: add next_expiry and other convenience from Futures module.
# Notice:  OSI-Notation is broken
module IB
  module Symbols
    module Options
      extend Symbols

			## usage:  IB::Symbols::Options.stoxx.merge( strike: 5000, expiry: 202404 )
      ##         IB::Symbols::Options.stoxx.merge( strike: 5000 ).next_expiry =>  fetch the next regulary
      ##                                                                          monthly option (3.rd friday)
      def self.contracts
        @contracts ||= {
          stoxx:  IB::Option.new(symbol: :ESTX50,
                                 expiry: IB::Option.next_expiry ,
                                 right: :put,
                                 trading_class: 'OESX',
                                 currency: 'EUR',
                                 exchange: 'EUREX',
                                 description: "Monthly settled ESTX50  Options"),
          spx:  IB::Option.new(  symbol: :SPX,
                                 expiry: IB::Option.next_expiry ,
                                 right: :put,
                                 trading_class: 'SPX',
                                 currency: 'USD',
                                 exchange: 'SMART',
                                 description: "Monthly settled SPX options"),
         spxw:  IB::Option.new(  symbol: :SPX,
                                 expiry: IB::Option.next_expiry ,
                                 right: :put,
                                 trading_class: 'SPXW',
                                 currency: 'USD', exchange: 'SMART',
                                 description: "Daily settled SPX options"),
         xsp:   IB::Option.new(  symbol: 'XSP',
                                 expiry: IB::Option.next_expiry ,
                                 right: :put,
                                 trading_class: 'XSP',
                                 currency: 'USD',
                                 exchange: 'SMART',
                                 description: "Daily settled Mini-SPX options"),
			  :spy => IB::Option.new( :symbol   => :SPY,
                                :expiry   => IB::Option.next_expiry,
                                :right    => :put,
                                :currency => "USD",
																:exchange => 'SMART',
                                :description => "SPY Put next expiration"),
			  :rut => IB::Option.new( :symbol   => :RUT,
                                :expiry   => IB::Option.next_expiry,
                                :right    => :put,
                                :currency => "USD",
																:exchange => 'SMART',
                                 description: "Monthly settled RUT options"),
			  :rutw => IB::Option.new( :symbol   => :RUT,
                                :expiry   => IB::Option.next_expiry,
                                :right    => :put,
                                :currency => "USD",
																:exchange => 'SMART',
                                 description: "Weekly settled RUT options"),
			  :russell => IB::Option.new( :symbol   => :RUT,                             # :russell  == :rut !
                                :expiry   => IB::Option.next_expiry,
                                :right    => :put,
                                :currency => "USD",
																:exchange => 'SMART',
                                 description: "Monthly settled RUT options"),
			  :mini_russell => IB::Option.new( :symbol   => :MRUT,
                                :expiry   => IB::Option.next_expiry,
                                :right    => :put,
                                :currency => "USD",
																:exchange => 'SMART',
                                :description => "Weekly settled Mini-Russell2000 options"),
       :aapl => IB::Option.new( :symbol => "AAPL",
                                :expiry => IB::Option.next_expiry,
                                :right => "C",
                                :strike => 150,
																:exchange => 'SMART',
                                :currency => 'USD',
                                :description => "Apple Call 130"),

			:ibm => IB::Option.new( symbol: 'IBM',
                            exchange: 'SMART',
                               right: :put,
                              expiry: IB::Option.next_expiry ,
												 description: 'IBM-Option Chain ( monthly expiry)'),
			:ibm_lazy_expiry => IB::Option.new( symbol: 'IBM',
                                           right: :put,
                                          strike: 180,
                                        exchange: 'SMART',
																		 description: 'IBM-Option Chain with strike 140'),
			:ibm_lazy_strike => IB::Option.new( symbol: 'IBM',
                                           right: :put,
																        exchange: 'SMART',
                                          expiry: IB::Option.next_expiry,
																		 description: 'IBM-Option Chain ( monthly expiry)'),

	    :goog100 => IB::Option.new( symbol: 'GOOG',
					                      currency: 'USD',
				                          strike: 100,
				                      multiplier: 100,
				                           right: :call,
                                exchange: 'SMART',
				                          expiry:  IB::Option.next_expiry,
				  description: 'Google Call Option with monthly expiry')
        }
      end
    end
  end
end
