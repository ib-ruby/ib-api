module IB
  module RollFuture
    # helper method to roll an existing future
    #
    # Argument is the expiry of the target-future.
    #

    def roll **args
      error "specify expiry to roll a future" if args.empty?
      args[:to] = args[:expiry] if args[:expiry].present?  && args[:expiry] =~ /[mwMW]$/
      args[:expiry]= IB::Spread.transform_distance( expiry, args.delete(:to  )) if args[:to].present?

      new_future =  merge( **args ).verify.first
      error "Cannot roll future; target is no IB::Contract" unless new_future.is_a? IB::Future
      target = IB::Spread.new exchange: exchange, symbol: symbol, currency: currency
      target.add_leg self, action:  :buy
      target.add_leg new_future, action: :sell
    end
  end


  module RollOption
    # helper method to roll an existing short-poption
    #
    # Arguments are strike and expiry of the target-option.
    #
    # Example:  r= Symbols::Options.rut.merge(strike: 2000).next_expiry.roll( strike:  1900 )
    #           r.to_human
    #        => " rolling <Option: RUT 20240516 put 2000.0 SMART USD> to <Option: RUT 20240516 put 1900.0 SMART USD>"
    #           r.combo_legs.to_human
    #        => ["<ComboLeg: buy 1 con_id 684936898 at SMART>", "<ComboLeg: sell 1 con_id 684936524 at SMART>"]
    #
    #   rolls the Option to another strike and/or expiry
    #
    #   Same Expiry, roll down the strike
    #   `r= Symbols::Options.rut.merge(strike: 2000).next_expiry.roll( strike:  1900 ) `
    #
    #   Same Expiry, roll to the next month
    #   `r= Symbols::Options.rut.merge(strike: 2000).next_expiry.roll( expiry:  '+1m' ) `

    def roll **args
      error "specify strike and expiry to roll option" if args.empty?
      args[:to] = args[:expiry] if args[:expiry].present?  && args[:expiry].to_s =~ /[mwMW]$/
      args[:expiry]= IB::Spread.transform_distance( expiry, args.delete(:to  )) if args[:to].present?

      new_option =  merge( ** args ).then{ | y | y.next_expiry{ y.expiry } }

      myself =  con_id.to_i.zero? ? self.verify.first  : self
      error "Cannot roll option; target is no IB::Contract" unless new_option.is_a? IB::Option
      error "Cannot roll option; Option cannot be verified" unless myself.is_a? IB::Option
      target = IB::Spread.new exchange: exchange, symbol: symbol, currency: currency
      target.add_leg myself, action:  :buy
      target.add_leg new_option, action: :sell
      target.description= target.description.sub(/added <Option:/, 'rolling <Option:').then{|y| y.gsub /added <Option/, 'to <Option'}
      target
    end
  end

  Connection.current.activate_plugin 'verify'

  class Future
    include RollFuture
  end

  class Option
    include RollOption
  end
end
