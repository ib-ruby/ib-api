module IB

  # OrderState represents dynamic (changeable) info about a single Order,
  # isolating these changes and making Order essentially immutable
  class OrderState < IB::Base
    include BaseProperties

    #p column_names
    belongs_to :order

    # Properties arriving via OpenOrder message
    prop :init_margin_after,   # Float: The impact the order would have on your initial margin.
      :maint_margin_after,     # Float: The impact the order would have on your maintenance margin.
      :equity_with_loan_after, # Float: The impact the order would have on your equity
      :init_margin_before, :maint_margin_before, :equity_with_loan_before,
      :init_margin_change, :maint_margin_change, :equity_with_loan_change,
      :commission, # double: Shows the commission amount on the order.
      :min_commission, # The possible min range of the actual order commission.
      :max_commission, # The possible max range of the actual order commission.

      :commission_currency, # String: Shows the currency of the commission.
      :warning_text, # String: Displays a warning message if warranted.

      :market_cap_price  # messages#incomming#orderstae#vers. 11

      # Properties arriving via OrderStatus message:
      prop :filled, #    int
      :remaining, # int
      [:price, :last_fill_price,], #    double
      [:average_price, :average_fill_price], # double
      :why_held # String: comma-separated list of reasons for order to be held.

      # Properties arriving in both messages:
      prop :local_id, #  int: Order id associated with client (volatile).
      :perm_id, #   int: TWS permanent id, remains the same over TWS sessions.
      :client_id, # int: The id of the client that placed this order.
      :parent_id, # int: The order ID of the parent (original) order, used
      :status => :s # String: one of
      #   ApiCancelled, PreSubmitted, PendingCancel, Cancelled, Submitted, Filled,
      #   Inactive, PendingSubmit, Unknown, ApiPending,
      #
      #  Displays the order status. Possible values include:
      # - PendingSubmit - indicates that you have transmitted the order, but
      #   have not yet received confirmation that it has been accepted by the
      #   order destination. NOTE: This order status is NOT sent back by TWS
      #   and should be explicitly set by YOU when an order is submitted.
      # - PendingCancel - indicates that you have sent a request to cancel
      #   the order but have not yet received cancel confirmation from the
      #   order destination. At this point, your order cancel is not confirmed.
      #   You may still receive an execution while your cancellation request
      #   is pending. NOTE: This order status is not sent back by TWS and
      #   should be explicitly set by YOU when an order is canceled.
      # - PreSubmitted - indicates that a simulated order type has been
      #   accepted by the IB system and that this order has yet to be elected.
      #   The order is held in the IB system until the election criteria are
      #   met. At that time the order is transmitted to the order destination
      #   as specified.
      # - Submitted - indicates that your order has been accepted at the order
      #   destination and is working.
      # - Cancelled - indicates that the balance of your order has been
      #   confirmed canceled by the IB system. This could occur unexpectedly
      #   when IB or the destination has rejected your order.
      # - ApiCancelled - canceled via API
      # - Filled - indicates that the order has been completely filled.
      # - Inactive - indicates that the order has been accepted by the system
      #   (simulated orders) or an exchange (native orders) but that currently
      #   the order is inactive due to system, exchange or other issues.
      #   

      validates_format_of :status, :without => /\A\z/, :message => 'must not be empty'
    validates_numericality_of :price, :average_price, :allow_nil => true
    validates_numericality_of :local_id, :perm_id, :client_id, :parent_id, :filled,
      :remaining, :only_integer => true, :allow_nil => true

    def self.valid_status? the_message
      valid_stati =  %w( ApiCancelled PreSubmitted PendingCancel Cancelled Submitted Filled
       Inactive PendingSubmit Unknown ApiPending)
     valid_stati.include?( the_message )
    end
  
    ## Testing Order state:

    def new?
      status.empty? || status == 'New'
    end

    # Order is in a valid, working state on TWS side
    def submitted?
      status =~ /Submit/
    end

    # Order is in a valid, working state on TWS side
    def pending?
      submitted? || status =~ /Pending/
    end

    # Order is in invalid state
    def inactive?
      new? || pending? || status =~ /Cancel/
    end

    def active?
      !inactive? # status == 'Inactive'
    end

    def complete_fill?
      status == 'Filled' && remaining == 0 # filled >= total_quantity # Manually corrected
    end

    # Comparison
    def == other

      super(other) ||
        other.is_a?(self.class) &&
        status == other.status &&
        local_id == other.local_id &&
        perm_id == other.perm_id &&
        client_id == other.client_id &&
        filled == other.filled &&
        remaining == other.remaining &&
        last_fill_price == other.last_fill_price &&
        init_margin_after == other.init_margin_after &&
        maint_margin_after == other.maint_margin_after &&
        equity_with_loan_after == other.equity_with_loan_after &&
        why_held == other.why_held &&
        warning_text == other.warning_text &&
        commission == other.commission
    end

    def to_human
      "<OrderState: #{status} ##{local_id}/#{perm_id} from #{client_id}" +
        (filled ? " filled #{filled}/#{remaining}" : '') +
        (last_fill_price ? " at #{last_fill_price}/#{average_fill_price}" : '') +
        (init_margin_after ? " margin #{init_margin_after}/#{maint_margin_after}" : '') +
        (equity_with_loan_after ? " equity #{equity_with_loan_after}" : '') +
        (commission && commission > 0 ? " fee #{commission}" : "") +
        (why_held ? " why_held #{why_held}" : '') +
        ((warning_text && warning_text != '') ? " warning #{warning_text}" : '') + ">"
    end

    alias to_s to_human
=begin
If an Order is submitted with the :what_if-Flag set, commission and margin are returned
via the order_state-Object.
=end
    def forcast
      { :init_margin => init_margin_after,
        :maint_margin => maint_margin_after,
        :equity_with_loan => equity_with_loan_after ,
        :commission => commission,
        :commission_currency=> commission_currency,
        :warning => warning_text }
    end
  end # class Order
end # module IB
