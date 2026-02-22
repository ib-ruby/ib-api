module IB
  class Future  < Contract
    validates_format_of :sec_type, :with => /\Afuture\z/,
      :message => "should be a Future"
    def default_attributes
      super.merge :sec_type => :future, currency:'USD'
    end
    def to_human
      "<Future: " + [symbol, expiry, currency].join(" ") + ">"
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
    class << self


      # This returns the next
      # quarterly expiration month after the current month.
      #
      # IB::Future.next_expiry returns the next quaterly expiration
      # IB::Option.next_expiry returns the next monthly expiration
      #
      #
      #
      def next_expiry d=Date.today, type: :quarter
        next_quarter_day = ->(year, month) do
          base_date = Date.new(year, month)
          base_wday  =  base_date.wday
          base_date + ( 5 > base_wday ? 5 - base_wday : 7 - base_wday + 5 ) +  14
        end
        next_quarter_day[ next_quarter_year(d), next_quarter_month(d) ].strftime("%Y%m%d")
#  /retired/        "#{ next_quarter_year(time) }#{ sprintf("%02d", next_quarter_month(time)) }"
      end

      private
      # Find the next front month of quarterly futures.
      # N.B. This will not work as expected during the front month before expiration, as
      # it will point to the next quarter even though the current month is still valid!
      def next_quarter_month d
        [3, 6, 9, 12].find { |month| month > d.month } || 3 # for December, next March
      end

      def next_quarter_year d
        next_quarter_month(d) < d.month ? d.year + 1 : d.year
      end
    end
  end
  end

