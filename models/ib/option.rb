module IB
  class Option < Contract

    validates_numericality_of :strike, :greater_than => 0
    validates_format_of :sec_type, :with => /\Aoption\z/,
      :message => "should be an option"
    validates_format_of :local_symbol, :with => /\A\w+\s*\d{6}[pcPC]\d{8}$|\A\z/,
      :message => "invalid OSI code"
    validates_format_of :right, :with => /\Aput$|^call\z/,
      :message => "should be put or call"


		# introduce Option.greek with reference to IB::OptionDetail-dataset
		#
		has_one :greek , as: :option_detail
    # For Options, this is contract's OSI (Option Symbology Initiative) name/code
    alias osi local_symbol

    def osi= value
      # Normalize to 21 char
      self.local_symbol = value.sub(/ /, ' '*(22-value.size))
    end

    # Make valid IB Contract definition from OSI (Option Symbology Initiative) code.
    # NB: Simply making a new Contract with *local_symbol* (osi) property set to a
    # valid OSI code works just as well, just do NOT set *expiry*, *right* or
    # *strike* properties in this case.
    # This class method provided as a backup and shows how to analyse OSI codes.
    def self.from_osi osi

      # Parse contract's OSI (OCC Option Symbology Initiative) code
      args = osi.match(/(\w+)\s?(\d\d)(\d\d)(\d\d)([pcPC])(\d+)/).to_a.drop(1)
      symbol = args.shift
      year = 2000 + args.shift.to_i
      month = args.shift.to_i
      day = args.shift.to_i
      right = args.shift.upcase
      strike = args.shift.to_i/1000.0

      # Set correct expiry date - IB expiry date differs from OSI if expiry date
      # falls on Saturday (see https://github.com/arvicco/option_mower/issues/4)
      expiry_date = Time.utc(year, month, day)
      expiry_date = Time.utc(year, month, day-1) if expiry_date.wday == 6

      new :symbol => symbol,
        :exchange => "SMART",
        :expiry => expiry_date.to_ib[2..7], # YYMMDD
        :right => right,
        :strike => strike
    end

    def default_attributes
      super.merge :sec_type => :option
      #self[:description] ||= osi ? osi : "#{symbol} #{strike} #{right} #{expiry}"
    end
		def == other
      super(other) || (  # finish positive, if contract#== is true
												  # otherwise, we most probably compare the response from IB with our selfmade input
			exchange == other.exchange &&
			include_expired == other.include_expired &&
			sec_type == other.sec_type  &&
			multiplier == other.multiplier &&
			strike == other.strike &&
			right == other.right &&
			multiplier == other.multiplier &&
			expiry == other.expiry )

		end


    # get the next (regular) expiry of the contract
    #
    # fetches for real contracts if verify is available
    #
    def next_expiry d =  Date.today
      exp = self.class.next_expiry d
      if IB::Connection.current.plugins.include? 'verify'
        self.expiry = exp[0..-3]
        verify.sort_by{| x | x.last_trading_day}
              .find_all{| y | y.expiry <= exp }
              .first
      else
        exp
      end

    end

    # returns the third friday of the (next) month  (class method)
    #
    # Argument: can either be Date, a String which parses to a Date or
    #           an Integer, yymm yyyymm or yyyymmdd -->  2406 or 202406  or 20240618
    #
    #           if called with a digit, this is interpretated a day of the current month
    #
    def self.next_expiry  base =  Date.today

      c =  0
      begin
      base_date = if base.is_a? Date
                      [ base.year, base.month ]
                  else
                    (base = Date.parse(base.to_s)).then { | d | [ d.year,d.month ] }
                  end.then{ |y,m| Date.new y,m }
      rescue Date::Error => e
        base =  base.to_s + "01"
        c =  c + 1
        retry if c == 1
      end
      error "Next-Expiry: Not a valid date: #{base}" if base_date.nil?
        friday =  5
        base_wday  =  base_date.wday
        b= base_date + ( friday > base_wday ? friday - base_wday : 7 - base_wday + friday ) +  14

        if b < base
          next_expiry base.then{| y | a = y + 25; a.strftime "%Y%m01" }
        else
          b.strftime "%Y%m%d"
        end
      end

    def to_human
      "<Option: " + [symbol, expiry, right, strike, exchange, currency].join(" ") + ">"
    end

  end # class Option

	class FutureOption   < Option
    def default_attributes
      super.merge :sec_type => :futures_option
		end
	end
end # module IB
