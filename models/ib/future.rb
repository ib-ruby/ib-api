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

    class << self
      # Find the next front month of quarterly futures.
      # N.B. This will not work as expected during the front month before expiration, as
      # it will point to the next quarter even though the current month is still valid!
      def next_quarter_month time=Time.now
        [3, 6, 9, 12].find { |month| month > time.month } || 3 # for December, next March
      end

      def next_quarter_year time=Time.now
        next_quarter_month(time) < time.month ? time.year + 1 : time.year
      end

      # WARNING: This returns the next
      # quarterly expiration month after the current month. Many futures
      # instruments have monthly contracts for the near months. This
      # method will not work for such contracts; it will return the next
      # quarter after the current month, even though the present month
      # has the majority of the trading volume.
      #
      def next_expiry time=Time.now
        "#{ next_quarter_year(time) }#{ sprintf("%02d", next_quarter_month(time)) }"
      end

    end
  end
  end

