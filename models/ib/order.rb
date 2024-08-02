module IB
  class Order < IB::Base
    include BaseProperties

    # General Notes:
    # 1. Placing Orders by con_id - When you place an order by con_id, you must
    # provide the con_id AND the exchange. If you provide extra fields when placing
    # an order by conid, the order may not work.

    # 2. Order IDs - Each order you place must have a unique Order ID. Increment
    # your own Order IDs to avoid conflicts between orders placed from your API application.

    # Main order fields
    prop :local_id,  # int: Order id associated with client (volatile).
      :client_id,    # int: The id of the client that placed this order.
      :perm_id,      # int: TWS permanent id, remains the same over TWS sessions.
      :quantity, :total_quantity, # int: The order quantity.

      :order_type, #  String: Order type.
      # Limit Risk: MTL / MKT PRT / QUOTE / STP / STP LMT / TRAIL / TRAIL LIMIT /  TRAIL LIT / TRAIL MIT
      # Speed of Execution: MKT / MIT / MOC / MOO / PEG MKT / REL
      # Price Improvement: BOX TOP / LOC / LOO / LIT / PEG MID / VWAP
      # Advanced Trading: OCA / VOL / SCALE
      # Other (no abbreviation): Bracket, Auction, Discretionary, Sweep-to-Fill,
      # Price Improvement Auction,  Block, Hidden, Iceberg/Reserve, All-or-None, Fill-or-Kill
      # See 'ib/constants.rb' ORDER_TYPES for a complete list of valid values.

      :limit_price, # double: LIMIT price, used for limit, stop-limit and relative
      #               orders. In all other cases specify zero. For relative
      #               orders with no limit price, also specify zero.
      :aux_price, #  double: default is set to "" (as implemented in python code)
      #            STOP price for stop-limit orders,
      #            OFFSET amount for relative orders.
      #            In all other cases, specify zero.

      :oca_group, #   String: Identifies a member of a one-cancels-all group.
      :oca_type, # int: Tells how to handle remaining orders in an OCA group
      #            when one order or part of an order executes. Valid values:
      #            - 1 = Cancel all remaining orders with block
      #            - 2 = Remaining orders are reduced in size with block
      #            - 3 = Remaining orders are reduced in size with no block
      #             If you use a value "with block" your order has
      #             overfill protection. This means that only one order in
      #             the group will be routed at a time to remove the
      #             possibility of an overfill.
      :parent_id, # int: The order ID of the parent (original) order, used
      #             for bracket (STP) and auto trailing stop (TRAIL) orders.
      :display_size, #   int: publicly disclosed order size for Iceberg orders.

      :trigger_method, # Specifies how Simulated Stop, Stop-Limit and Trailing
      #                  Stop orders are triggered. Valid values are:
      #      0 - Default, "double bid/ask" for OTC/US options, "last" otherswise.
      #      1 - "double bid/ask" method, stop orders are triggered based on
      #          two consecutive bid or ask prices.
      #      2 - "last" method, stops are triggered based on the last price.
      #      3 - double last method.
      #      4 - bid/ask method. For a buy order, a single occurrence of the
      #          bid price must be at or above the trigger price. For a sell
      #          order, a single occurrence of the ask price must be at or
      #          below the trigger price.
      #      7 - last or bid/ask method. For a buy order, a single bid price
      #          or the last price must be at or above the trigger price.
      #          For a sell order, a single ask price or the last price
      #          must be at or below the trigger price.
      #      8 - mid-point method, where the midpoint must be at or above
      #          (for a buy) or at or below (for a sell) the trigger price,
      #          and the spread between the bid and ask must be less than
      #          0.1% of the midpoint

      :good_after_time, # Indicates that the trade should be submitted after the
      #        time and date set, format YYYYMMDD HH:MM:SS (seconds are optional).
      :good_till_date, # Indicates that the trade should remain working until the
      #        time and date set, format YYYYMMDD HH:MM:SS (seconds are optional).
      #        You must set the :tif to GTD when using this string.
      #        Use an empty String if not applicable.

      :rule_80a, # Individual = 'I', Agency = 'A', AgentOtherMember = 'W',
      #            IndividualPTIA = 'J', AgencyPTIA = 'U', AgentOtherMemberPTIA = 'M',
      #            IndividualPT = 'K', AgencyPT = 'Y', AgentOtherMemberPT = 'N'
      :min_quantity, #     int: Identifies a minimum quantity order type.
      :percent_offset, #   double: REL-Ordes – percent offset amount
      :trail_stop_price, # double: TRAILLIMIT orders only
      # As of client v.56, we receive trailing_percent in openOrder
      :trailing_percent,

      # Financial advisors only - use an empty String if not applicable.
      :fa_group, :fa_profile, :fa_method, :fa_percentage,
      :model_code ,  # string, no further reference in docs.
      # Institutional orders only!
      :origin, #          0=Customer, 1=Firm
      :order_ref, #       String: Order reference. Customer defined order ID tag.
      :short_sale_slot, # 1 - you hold the shares,
      #                   2 - they will be delivered from elsewhere.
      #                   Only for Action="SSHORT
      :designated_location, # String: set when slot==2 only
      :exempt_code, #       int

      #  Clearing info
      :account, #  String: The account number (Uxxx). For institutional customers only.
      :settling_firm, #    String: Institutional only
      :clearing_account, # String: For IBExecution customers: Specifies the
      #                  true beneficiary of the order. This value is required
      #                  for FUT/FOP orders for reporting to the exchange.
      :clearing_intent, # IBExecution customers: "", IB, Away, PTA (post trade allocation).

      # SMART routing only
      :discretionary_amount, # double: The amount off the limit price
      #                        allowed for discretionary orders.

      # BOX or VOL ORDERS ONLY
      :auction_strategy, # For BOX exchange only. Valid values:
      #      1=AUCTION_MATCH, 2=AUCTION_IMPROVEMENT, 3=AUCTION_TRANSPARENT
      :starting_price, #   double: Starting price. Valid on BOX orders only.
      :stock_ref_price, #  double: The stock reference price, used for VOL
      # orders to compute the limit price sent to an exchange (whether or not
      # Continuous Update is selected), and for price range monitoring.
      :delta, #            double: Stock delta. Valid on BOX orders only.

      # Pegged to stock or VOL orders. For price improvement option orders
      # on BOX and VOL orders with dynamic management:
      :stock_range_lower, #   double: The lower value for the acceptable
      #                               underlying stock price range.
      :stock_range_upper, #   double  The upper value for the acceptable
      #                               underlying stock price range.

      # VOLATILITY ORDERS ONLY:
      # http://www.interactivebrokers.com/en/general/education/pdfnotes/PDF-VolTrader.php
      :volatility, #  double: What the price is, computed via TWSs Options
      #               Analytics. For VOL orders, the limit price sent to an
      #               exchange is not editable, as it is the output of a
      #               function. Volatility is expressed as a percentage.
      :volatility_type, # int: How the volatility is calculated: 1=daily, 2=annual
      :reference_price_type, # int: For dynamic management of volatility orders:
      #     - 1 = Average of National Best Bid or Ask,
      #     - 2 = National Best Bid when buying a call or selling a put;
      #           and National Best Ask when selling a call or buying a put.
      :continuous_update, # int: Used for dynamic management of volatility orders.
      # Determines whether TWS is supposed to update the order price as the underlying
      # moves. If selected, the limit price sent to an exchange is modified by TWS
      # if the computed price of the option changes enough to warrant doing so. This
      # is helpful in keeping the limit price up to date as the underlying price changes.
      :delta_neutral_order_type, # String: Enter an order type to instruct TWS
      #    to submit a delta neutral trade on full or partial execution of the
      #    VOL order. For no hedge delta order to be sent, specify NONE.
      #    Valid values - LMT, MKT, MTL, REL, MOC
      :delta_neutral_aux_price, #  double: Use this field to enter a value if
      #           the value in the deltaNeutralOrderType field is an order
      #           type that requires an Aux price, such as a REL order.

      # As of client v.52, we also receive delta... params in openOrder
      :delta_neutral_designated_location,
      :delta_neutral_con_id,
      :delta_neutral_settling_firm,
      :delta_neutral_clearing_account,
      :delta_neutral_clearing_intent,
      # Used when the hedge involves a stock and indicates whether or not it is sold short.
      :delta_neutral_short_sale,
      #  Has a value of 1 (the clearing broker holds shares) or 2 (delivered from a third party).
      #  If you use 2, then you must specify a deltaNeutralDesignatedLocation.
      :delta_neutral_short_sale_slot,
      # Specifies whether the order is an Open or a Close order and is used
      # when the hedge involves a CFD and and the order is clearing away.
      :delta_neutral_open_close,

      # HEDGE ORDERS ONLY:
      # As of client v.49/50, we can now add hedge orders using the API.
      # Hedge orders are child orders that take additional fields. There are four
      # types of hedging orders supported by the API: Delta, Beta, FX, Pair.
      # All hedge orders must have a parent order submitted first. The hedge order
      # should set its :parent_id. If the hedgeType is Beta, the beta sent in the
      # hedgeParm can be zero, which means it is not used. Delta is only valid
      # if the parent order is an option and the child order is a stock.

      :hedge_type, # String: D = Delta, B = Beta, F = FX or P = Pair
      :hedge_param, # String; value depends on the hedgeType; sent from the API
      # only if hedge_type is NOT null. It is required for Pair hedge order,
      # optional for Beta hedge orders, and ignored for Delta and FX hedge orders.

      # COMBO ORDERS ONLY:
      :basis_points, #      double: EFP orders only
      :basis_points_type, # double: EFP orders only

      # ALGO ORDERS ONLY:
      :algo_strategy, # String
      :algo_params, # public Vector<TagValue> m_algoParams; ?!
      :algo_id,     # since Vers. 71
      # SCALE ORDERS ONLY:
      :scale_init_level_size, # int: Size of the first (initial) order component.
      :scale_subs_level_size, # int: Order size of the subsequent scale order
      #             components. Used in conjunction with scaleInitLevelSize().
      :scale_price_increment, # double: Price increment between scale components.
      #                         This field is required for Scale orders.

      # As of client v.54, we can receive additional scale order fields:
      :scale_price_adjust_value,
      :scale_price_adjust_interval,
      :scale_profit_offset,
      :scale_init_position,
      :scale_init_fill_qty,
      :scale_table,     # Vers 69
      :active_start_time,   # Vers 69
      :active_stop_time,    # Vers 69
      # pegged to benchmark
      :reference_contract_id,
      :pegged_change_amount,
      :reference_change_amount,
      :reference_exchange_id ,

      :conditions,    # Conditions determining when the order will be activated or canceled.
      ### http://xavierib.github.io/twsapidocs/order_conditions.html
      :conditions_ignore_rth,  # bool: Indicates whether or not conditions will also be valid outside Regular Trading Hours
      :conditions_cancel_order,# bool: Conditions can determine if an order should become active or canceled.
      #AdjustedOrderParams
      :adjusted_order_type,
      :trigger_price,
      :trail_stop_price,
      :limit_price_offset,  # used in trailing stop limit + trailing limit orders
      :adjusted_stop_price,
      :adjusted_stop_limit_price,
      :adjusted_trailing_amount,
      :adjustable_trailing_unit,
      :ext_operator ,               # 105: MIN_SERVER_VER_EXT_OPERATOR
          # This is a regulartory attribute that applies
          # to all US Commodity (Futures) Exchanges, provided
          # to allow client to comply with CFTC Tag 50 Rules.
      :soft_dollar_tier_name,        # 106: MIN_SERVER_VER_SOFT_DOLLAR_TIER
      :soft_dollar_tier_value,
      :soft_dollar_tier_display_name,
          # Define the Soft Dollar Tier used for the order.
          # Only provided for registered professional advisors and hedge and mutual funds.
          # format: "#{name}=#{value},#{display_name}", name and value are used in the
          #       order-specification. Its included as ["#{name}","#{value}"] pair

      :cash_qty,   # decimal : The native cash quantity
      :mifid_2_decision_maker,
      :mifid_2_decision_algo,
      :mifid_2_execution_maker,
      :mifid_2_execution_algo,
      :dont_use_auto_price_for_hedge,#    => :bool,
      :discretionary_up_to_limit_price,#  => :bool,
      :use_price_management_algo,#        => :bool,
      :duration                 ,#        => :int,
      :post_to_ats              ,#        => :int,
      :auto_cancel_parent,       #        => :bool
      :is_O_ms_container,
      :advanced_order_reject,
      :manual_order_time,
      :min_trade_qty,
      :min_compete_size,
      :compete_against_best_offset,
      :mid_offset_at_whole,
      :mid_offset_at_half,
      :customer_account,
      :professional_account



    # Properties with complex processing logics
    prop :tif, #  String: Time in Force (time to market): DAY/GAT/GTD/GTC/IOC
      :random_size => :bool,
      :random_price => :bool,
      :scale_auto_reset => :bool,
      :scale_random_percent => :bool,
      :solicided  => :bool,
      :what_if => :bool,                # Only return pre-trade commissions and margin info, do not place
      :not_held => :bool,               # Not Held
      :outside_rth => :bool,            # Order may trigger or fill outside of regular hours. (WAS: ignore_rth)
      :hidden => :bool,                 # Order will not be visible in market depth. ISLAND only.
      :transmit => :bool,               # If false, order will be created but not transmitted.
      :block_order => :bool,            # This is an ISE Block order.
      :sweep_to_fill => :bool,          # This is a Sweep-to-Fill order.
      :override_percentage_constraints => :bool,
      # TWS Presets page constraints ensure that your price and size order values
      # are reasonable. Orders sent from the API are also validated against these
      # safety constraints, unless this parameter is set to True.
      :all_or_none => :bool,             #  AON
      :opt_out_smart_routing => :bool,   # Australian exchange only, default false
      :is_pegged_change_amount_decrease => :bool, # pegged_to_benchmark-oders, default false (increase)
      :open_close => PROPS[:open_close], # Originally String: O=Open, C=Close ()
      # for ComboLeg compatibility: SAME = 0; OPEN = 1; CLOSE = 2; UNKNOWN = 3;
      [:side, :action] => PROPS[:side]   # String: Action/side: BUY/SELL/SSHORT/SSHORTX

    prop :placed_at,
      :modified_at,
      :leg_prices,
      :algo_params,
      :combo_params   # Valid tags are LeginPrio, MaxSegSize, DontLeginNext, ChangeToMktTime1,
                      # ChangeToMktTime2, ChangeToMktOffset, DiscretionaryPct, NonGuaranteed,
                      # CondPriceMin, CondPriceMax, and PriceCondConid.
        # to set an execuction-range of a security:
        #      PriceCondConid, 10375;  -- conid of the combo-leg
        #      CondPriceMax, 62.0;     -- max and min-price
        #      CondPriceMin.;60.0

      prop :etrade_only, :firm_quote_only, :nbbo_price_cap  #  depreciated, needed for open-order message
#    prop :misc1, :misc2, :misc3, :misc4, :misc5, :misc6, :misc7, :misc8 # just 4 debugging

    alias order_combo_legs leg_prices
    alias smart_combo_routing_params combo_params

    # serialize is included for active_record compatibility
  #  serialize :leg_prices
  #  serialize :conditions
  #  serialize :algo_params, Hash
   # serialize :combo_params
 #   serialize :soft_dollar_tier_params, HashWithIndifferentAccess
    serialize :mics_options, Hash

    # Order is always placed for a contract. We explicitly set this link.
    belongs_to :contract

    # Order has a collection of Executions if it was filled
    has_many :executions

    # Order has a collection of OrderStates. The last one is always current
    has_many :order_states
    # Order can have multible conditions
    has_many  :conditions

    def order_state
      order_states.last
    end

    def order_state= state
      self.order_states.push case state
      when IB::OrderState
        state
      when Symbol, String
        IB::OrderState.new :status => state
      end
    end

    # Some properties received from IB are separated into OrderState object,
    # but they are still readable as Order properties through delegation:
    # Properties arriving via OpenOrder message:
    [:commission, # double: Shows the commission amount on the order.
     :commission_currency, # String: Shows the currency of the commission.
     :min_commission, # The possible min range of the actual order commission.
     :max_commission, # The possible max range of the actual order commission.
     :warning_text, # String: Displays a warning message if warranted.
     :status, # String: Displays the order status. See OrderState for values
     # Properties arriving via OrderStatus message:
     :filled, #    int
     :remaining, # int
     :price, #    double
     :last_fill_price, #    double
     :average_price, # double
     :average_fill_price, # double
     :why_held, # String: comma-separated list of reasons for order to be held.
     # Testing Order state:
     :new?,
     :submitted?,
     :pending?,
     :active?,
     :inactive?,
     :complete_fill?
     ].each { |property| define_method(property) { order_state.send(property) } }

    [:init_margin, # Float: The impact the order would have on your initial margin.
     :equity_with_loan, # Float: The impact the order would have on your equity
     :maint_margin # Float: The impact the order would have on your maintenance margin.
    ].each { |property| define_method(property) { order_state.send(property.to_s+"_change") } }

    # Order is not valid without correct :local_id
    validates_numericality_of :local_id, :perm_id, :client_id, :parent_id,
      :total_quantity, :min_quantity, :display_size,
      :only_integer => true, :allow_nil => true

    validates_numericality_of :limit_price, :aux_price, :allow_nil => true


    def default_attributes        # default valus are taken from order.java
                                  # public Order() { }
      super.merge(
      :active_start_time => "",   # order.java # 470    # Vers 69
      :active_stop_time => "",    # order.java # 471  # Vers 69
      :adjusted_order_type => "",
      :algo_params => Hash.new, #{},
      :algo_strategy => '',
      :algo_id => '' ,            # order.java # 495
      :all_or_none => false,
      :auction_strategy => :none,
      :aux_price => server_version < KNOWN_SERVERS[ :min_server_ver_trailing_percent ] ?  0 : '',
      :block_order => false,
      :combo_params => Hash.new,
      :conditions => [],
      :continuous_update => 0,
      :delta => "",
      :designated_location => '', # order.java # 487
      :display_size => nil,
      :discretionary_amount => 0,
      :exempt_code => -1,
      :ext_operator  => '' ,  # order.java # 499
      :hedge_param => [],
      :hidden => false,
      :is_pegged_change_amount_decrease => false,
      :leg_prices => [],
      :limit_price => server_version < KNOWN_SERVERS[ :min_server_ver_order_combo_legs_price ] ?  0 : '',
      :min_quantity => "",
      :model_code => "",
      :not_held => false,  # order.java # 494
      :oca_type => :none,
      :order_type => :limit,
      :open_close => :open,   # order.java #
      :opt_out_smart_routing => false,
     :order_state => IB::OrderState.new( :status => 'New',
                                         :filled => 0,
                                      :remaining => 0,
                                          :price => 0,
                                  :average_price => 0 ),
      :origin => :customer,
      :outside_rth => false, # order.java # 472
      :override_percentage_constraints => false,
      :percent_offset =>"",
      :parent_id => 0,
      :pegged_change_amount => 0.0,
      :random_size => false,    #oder.java 497      # Vers 76
      :random_price => false,   # order.java # 498    # Vers 76
      :reference_price_type => "",
      :reference_contract_id => 0,
      :reference_change_amount => 0.0,
      :reference_exchange_id => "",
      :scale_auto_reset => false,  # order.java # 490
      :scale_random_percent => false, # order.java # 491
      :scale_table => "", # order.java # 492
      :stock_range_lower => "",
      :stock_range_upper => "",
      :stock_ref_price =>"",
      :short_sale_slot => :default,
      :solicided =>  false,  # order.java #  496
      :sweep_to_fill => false,
      :tif => :day,
      :trail_stop_price => "",
      :trailing_percent => "",
      :transmit => true,
      :trigger_method => :default,
      :use_price_management_algo => "",
      :volatility_type => :annual,
      :what_if => false,  # order.java # 493

      )  # closing of merge
        end

    def serialize_combo_legs(contract)
      if contract.bag?
        [ contract.serialize_legs,
          leg_prices.size,
          leg_prices,
          combo_params.size,
          combo_params.to_a
        ]
      else
        []
      end
    end
    def serialize_main_order_fields
        include_short = -> (s) { if s == :short then 'SSHORT' else s == :short_exempt ? 'SSHORTX' : s.to_sup end }
        include_total_quantity = -> (q) { server_version >= KNOWN_SERVERS[ :min_server_ver_fractional_positions ] ?             q.to_d : q.to_i }

          [ include_short[ side ],
           include_total_quantity[ total_quantity ],
           self[ :order_type ], # Internal code, 'LMT' instead of :limit
           limit_price ,
           aux_price  ]
    end

    def serialize_extended_order_fields

          [ self[ :tif ],
           oca_group,
           account,
           open_close.to_sup[0],  # "O" or "C"
           self[ :origin ],  # translates :customer, :firm  to 0,1
           order_ref,
           transmit,
           parent_id,
           block_order,
           sweep_to_fill,
           display_size,
           self[ :trigger_method ],
           outside_rth,
           hidden ]
    end

    def serialize_auxilery_order_fields
          [ "", # deprecated shares_allocation field
           discretionary_amount,
           good_after_time,
           good_till_date,
           serialize_advisory_order_fields
           ]
    end

=begin rdoc
Format of serialisation

  count of records
  for each condition: conditiontype, condition-fields
=end
    def serialize_conditions
      if conditions.empty?
        [ 0 ]
      else
        [ conditions.size ] + conditions.map( &:serialize ) + [ conditions_ignore_rth, conditions_cancel_order ]
      end
    end

    def serialize_algo
      return [''] if algo_strategy.blank?
      [algo_strategy, algo_params.size] + algo_params.to_a
    end

    def serialize_advisory_order_fields
         aof = [ fa_group, fa_method, fa_percentage, fa_profile ]
         if server_version < KNOWN_SERVERS[:min_server_ver_fa_profile_desupport]
           aof
         else
           aof[ 0..-2 ]
         end
    end

    def serialize_volatility_order_fields
           if volatility.present?
           [ volatility ,       #              Volatility orders
           self[:volatility_type] ] #     default: annual volatility
            else
            ["",""]
           end
    end

    def serialize_delta_neutral_order_fields

           if delta_neutral_order_type && delta_neutral_order_type != :none
             [
              delta_neutral_con_id,
              delta_neutral_settling_firm,
              delta_neutral_clearing_account,
              self[ :delta_neutral_clearing_intent ],
              delta_neutral_open_close,
              delta_neutral_short_sale,
              delta_neutral_short_sale_slot,
              delta_neutral_designated_location
             ]
           else
             ['', '']
           end
    end

    def serialize_scale_order_fields

      a=  [ scale_init_level_size || "",
            scale_subs_level_size || "",
            scale_price_increment || "" ]

      # Support for extended scale orders parameters
      if scale_price_increment.to_i > 0
      a << [ scale_price_adjust_value || "",
             scale_price_adjust_interval || "",
             scale_profit_offset || "",
             scale_auto_reset, #  default: false,
             scale_init_position || "",
             scale_init_fill_qty || "",
             scale_random_percent # default: false,
        ]
      end

      a << scale_table
      a << active_start_time || ""
      a << active_stop_time || ""
      a
    end
    def serialize_pegged_order_fields
      if order_type == :pegged_to_benchmark && server_version >= KNOWN_SERVERS[ :min_server_ver_pegged_to_benchmark ]
      [ reference_contract_id,
        is_pegged_change_amount_decrease,
        pegged_change_amount,
        reference_change_amount,
        reference_exchange_id ]
      else
        []
      end
    end

    def serialize_advanced_option_order_fields

            [ starting_price ,  # pegged to stock
            stock_ref_price ,   # pegged to stock
            delta ,             # pegged to stock
            stock_range_lower , # pegged
            stock_range_upper   # pegged
            ]
    end

   def serialize_soft_dollar_tier
      [ soft_dollar_tier_name,
        soft_dollar_tier_value
      ]
    end


   def serialize_mifid_order_fields
          a = []
            if server_version >= KNOWN_SERVERS[:min_server_ver_decision_maker]  #  138
            a <<  [ mifid_2_decision_maker, mifid_2_decision_algo ]
            end
            if server_version >= KNOWN_SERVERS[:min_server_ver_mifid_execution]  # 139
            a << [ mifid_2_execution_maker, mifid_2_execution_algo ]
            end
           a
   end

   def serialize_peg_best_and_mid
     return [] unless server_version >= KNOWN_SERVERS[:min_server_ver_pegbest_pegmid_offsets]
     a =  []
     send_mid_offsets = false
     a << min_trade_qty  if contract.exchange == 'IBKRATS'
     if order.type == :pegged_to_best
       a << min_compete_size
       a << compete_against_best_offset
       send_mid_offsets = true if compete_against_best_offset.nil? # TODO: float max?
     end
     if order.type == :pegged_to_midpoint
       send_mid_offsets = true
     end
     if send_mid_offsets
       a << mid_offset_at_whole
       a << mid_offset_at_half
     end
     a
   end

    def serialize_misc_options
      ""      # Vers. 70
    end
    # Order comparison
    def == other
      super(other) ||
        other.is_a?(self.class) &&
        (perm_id && other.perm_id && perm_id == other.perm_id ||
         local_id == other.local_id && # ((p __LINE__)||true) &&
         (client_id == other.client_id || client_id == 0 || other.client_id == 0) &&
         parent_id == other.parent_id &&
         tif == other.tif &&
         action == other.action &&
         order_type == other.order_type &&
         total_quantity == other.total_quantity &&
         limit_price == other.limit_price  &&
         aux_price == other.aux_price &&
         origin == other.origin &&
         designated_location == other.designated_location &&
         exempt_code == other.exempt_code &&
         what_if == other.what_if &&
         algo_strategy == other.algo_strategy &&
         algo_params == other.algo_params)

        # TODO: compare more attributes!
        end

    def to_s #human
      "<Order:" + instance_variables.map do |key|
        value = instance_variable_get(key)
        " #{key}=#{value}" unless value.nil? || value == '' || value == 0
      end.compact.join(',') + " >"
    end

    def to_human
      misc = []
      misc <<  algo_strategy if algo_strategy.present?
      misc << "benchmark con-id: #{reference_contract_id}" if reference_contract_id.to_i >0
      misc << "vola: #{volatility}" if volatility.present?
      misc << "fee: #{commission}" if commission.present?
      misc << "dc: #{discretionary_amount}," if discretionary_amount.to_i != 0
      "<Order: " + (order_ref.present? ? order_ref.to_s : '') +
        "#{self[:order_type]} #{self[:tif]} #{action} #{total_quantity} " + " @ " +
        (limit_price ? "#{limit_price} " : '') + "#{status} " +
        ((aux_price && aux_price != 0) ? "/#{aux_price}" : '') +
        "##{local_id}/#{perm_id} from #{client_id}" +
        (account ? "/#{account}" : '') +
        (misc.empty? ? "" : " ") + misc.join( " " ) + ">"
    end


    def table_header
      [ 'account','status', '', 'Type', 'tif', 'action', 'amount','price' , 'misc' ]
    end

    def table_row
      misc = []
      misc <<  algo_strategy if algo_strategy.present?
      misc << " benchmark con-id: #{reference_contract_id}" if reference_contract_id.to_i > 0
      misc << " vola: #{volatility}" if volatility.present?
      misc << " fee: #{commission}" if commission.present?
      misc << " id: #{local_id}" if local_id.to_i > 0
      misc << " dc: #{discretionary_amount}," if discretionary_amount.to_i != 0
        [ account,  order_ref.present? ? order_ref.to_s : status,
        contract.to_human[1..-2],
        self[:order_type] ,
        self[:tif],
        action,
        total_quantity,
        ((limit_price && !limit_price.zero?) ? "#{limit_price} " : '') + ((aux_price && !aux_price.zero?) ? "/#{aux_price}" : '') ,
        misc.join( " " ) ]
    end

    def serialize_rabbit
      { 'Contract' => contract.present? ? contract.serialize( :option, :trading_class ): '' ,
     'Order' =>  self,
     'OrderState' => order_state}
    end

  end # class Order
end # module IB
