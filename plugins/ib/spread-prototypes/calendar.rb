module IB

    module  Calendar

      extend SpreadPrototype
      class << self


#  Fabricate a Calendar-Spread from a Master-Option
#  -----------------------------------------
#  If one Leg is known, the other is build through replacing the expiry
#  The second leg is always SOLD !
#
#   Call with
#   IB::Calendar.fabricate  an_option, the_other_expiry
      def fabricate master, the_other_expiry

        error "Argument must be a IB::Future or IB::Option" unless  [:option, :future_option, :future ].include? master.sec_type
        m = master.verify.first
        error "Argument is a #{master.class}, but Verification failed" unless m.is_a? IB::Contract
        the_other_expiry =  the_other_expiry.values.first if the_other_expiry.is_a?(Hash)
        back = IB::Spread.transform_distance m.expiry, the_other_expiry
        the_other_contract =  m.merge( expiry: back ).verify.first
        error "Verification of second leg failed" unless the_other_contract.is_a? IB::Contract
        target = IB::Spread.new exchange: m.exchange, symbol: m.symbol, currency: m.currency
        target.add_leg m, action:  :buy
        target.add_leg the_other_contract, action: :sell

#        calendar =  m.roll expiry: back
        error "Initialisation of Legs failed" if target.legs.size != 2
        target.description =  the_description( target )
        target  #  return fabricated spread
      end


#  Build  Vertical out of an Underlying
#  -----------------------------------------
#  Needed attributes: :strike, :expiry( front: expiry1, back: expiry2 ), right
#
#  Optional: :trading_class, :multiplier
#
#   Call with
#   IB::Calendar.build from: IB::Contract,  front: an_expiry,  back: an_expiry,
#                                           right: {put or call}, strike: a_strike
      def build from:, front: nil, back: nil, right: :put, strike: nil,  **fields
        underlying = if from.is_a?  IB::Option
                       right ||= from.right
                       front ||= from.expiry
                       strike ||= from.strike
                       details = from.verify.first.contract_detail
                       IB::Contract.new( con_id: details.under_con_id,
                                        currency: from.currency).verify.first.essential
                     else
                       error "missing essential parameter: `strike`" unless strike.present?
                       from
                     end
        error "`front:` and `back:` expiries are required" unless front.present? && back.present?
        kind = { :front => front, :back => back }
        initialize_spread( underlying ) do | the_spread |
          leg_prototype  = IB::Option.new underlying.invariant_attributes.except( :sec_type )
            .slice( :currency, :symbol, :exchange )
            .merge(defaults)
            .merge( fields )
            .merge( strike: strike )
          kind[:back] = IB::Spread.transform_distance front, back
          leg_prototype.sec_type = 'FOP' if underlying.is_a?(IB::Future)
          leg1 = leg_prototype.merge( expiry: kind[:front] ).verify.first
          leg2 = leg_prototype.merge( expiry: kind[:back] ).verify.first
          unless leg2.is_a? IB::Option
            leg2_trading_class = ''
            leg2 = leg_prototype.merge( expiry: kind[:back] ).verify.first
          end
          the_spread.add_leg leg1 , action: :buy
          the_spread.add_leg leg2 , action: :sell
          error "Initialisation of Legs failed" if the_spread.legs.size != 2
          the_spread.description =  the_description( the_spread )  rescue nil
        end
      end

      def defaults
      super.merge right: :put
#                expiry: IB::Future.next_expiry,
      end


      def the_description spread
      x= [ spread.combo_legs.map(&:weight) , spread.legs.map( &:last_trading_day )].transpose
      f_or_o = if spread.legs.first.is_a?(IB::Future)
                 "Future"
               else
                 "#{spread.legs.first.right}(#{spread.legs.first.strike})"
               end
      "<Calendar #{spread.symbol} #{f_or_o} [#{x.map{|w,l_t_d| "#{w}:#{Date.parse(l_t_d).strftime("%b %Y")}"}.join( '|+|' )}]>"
      end
     end # class
    end # module vertical
end  # module ib
