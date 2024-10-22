# Frequently used stock contracts definitions
# TODO: auto-request :ContractDetails from IB if unknown symbol is requested?
module IB
  module Symbols
    module  Combo
      extend Symbols

      def self.contracts
        base = 4500
        @contracts ||= { #super.merge(
          stoxx_straddle: IB::Straddle.build( from: IB::Symbols::Index.stoxx, strike: base,
                                             expiry: IB::Option.next_expiry, trading_class: 'OESX' ) ,
          stoxx_calendar: IB::Calendar.build( from: IB::Symbols::Index.stoxx, strike: base, back: '2m' ,
                                             front: IB::Option.next_expiry, trading_class: 'OESX' ),
         stoxx_butterfly: IB::Butterfly.fabricate( IB::Symbols::Options.stoxx.merge( strike: base - 200,
                                                                    expiry: IB::Option.next_expiry),
                                                                    front: base - 400, back: base),
          stoxx_vertical: IB::Vertical.build( from: IB::Symbols::Index.stoxx, sell: base - 200, buy: base + 200, right: :put,
                                            expiry: IB::Option.next_expiry, trading_class: 'OESX'),
             zn_calendar: IB::Calendar.fabricate( IB::Symbols::Futures.zn.next_expiry, '3m') ,

             dbk_straddle: Bag.new( symbol: 'DBK', currency: 'EUR', exchange: 'EUREX', combo_legs:
                                [  ComboLeg.new( con_id: 270581032 , action: :buy, exchange: 'DTB', ratio: 1),   #DBK Dez20 2018 C
                                   ComboLeg.new( con_id: 270580382,  action: :buy, exchange: 'DTB', ratio: 1 ) ], #DBK Dez 20 2018 P
                                description: 'Option Straddle: Deutsche Bank(20)[Dez 2018]'),
                   ib_mcd: Bag.new( symbol: 'IBKR,MCD', currency: 'USD', exchange: 'SMART',
                                combo_legs: [  ComboLeg.new( con_id: 43645865, action: :buy, ratio: 1), # IKBR STK
                                               ComboLeg.new( con_id: 9408,     action: :sell,ratio: 1 ) ], # MCD STK
                               description: 'Stock Spread: Buy Interactive Brokers, sell Mc Donalds'),

             vix_calendar:  Bag.new( symbol: 'VIX', currency: 'USD', exchange: 'CFE',
                                 combo_legs: [  ComboLeg.new( con_id: 256038899, action: :buy, exchange: 'CFE', ratio: 1), #  VIX FUT 201708
                                                ComboLeg.new( con_id: 260564703,  action: :sell, exchange: 'CFE', ratio: 1 ) ], # VIX FUT 201709
                                description: 'VixFuture  Calendar-Spread August - September 2017'
                                   )
        }
      # )
      end

    end
  end
end
