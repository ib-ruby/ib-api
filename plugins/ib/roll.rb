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
    # helper method to roll an existing option
    #
    # Arguments are strike and expiry of the target-option.
    #
    # Example:  ge= Symbols::Options.ge.verify.first.roll( strike: 130 )
    #           ge.to_human
    #  => " added <Option: GE 20210917 call 7.0 SMART USD> added <Option: GE 20210917 call 13.0 SMART USD>"
    #
    #   rolls the Option to another strike

    def roll **args
      error "specify strike and expiry to roll option" if args.empty?
      args[:to] = args[:expiry] if args[:expiry].present?  && args[:expiry].to_s =~ /[mwMW]$/
      args[:expiry]= IB::Spread.transform_distance( expiry, args.delete(:to  )) if args[:to].present?

      new_option =  merge( **args ).verify.first
      myself =  con_id.to_i.zero? ? self.verify.first  : self
      error "Cannot roll option; target is no IB::Contract" unless new_option.is_a? IB::Option
      error "Cannot roll option; Option cannot be verified" unless myself.is_a? IB::Option
      target = IB::Spread.new exchange: exchange, symbol: symbol, currency: currency
      target.add_leg myself, action:  :buy
      target.add_leg new_option, action: :sell
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
