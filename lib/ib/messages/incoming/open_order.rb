module IB
  module Messages
    module Incoming
      using IB::Support
      # OpenOrder is the longest message with complex processing logics
      OpenOrder =
          def_message [5, 0],		# updated to v. 34 according to python (decoder.py processOpenOrder)
                      [ :order, :local_id,             :int],

                      [ :contract,                     :contract], # read standard-contract
											# [ con_id, symbol,. sec_type, expiry, strike, right, multiplier,
											#	exchange, currency, local_symbol, trading_class ]

                      [ :order, :action,               :string ],
                      [ :order, :total_quantity,       :decimal ],
                      [ :order, :order_type,           :string ],
                      [ :order, :limit_price,          :decimal ],
                      [ :order, :aux_price,            :decimal ],
                      [ :order, :tif,                  :string ],
                      [ :order, :oca_group,            :string ],
                      [ :order, :account,              :string ],
                      [ :order, :open_close,           :string ],
                      [ :order, :origin,               :int ],
                      [ :order, :order_ref,            :string ],
                      [ :order, :client_id,            :int ],
                      [ :order, :perm_id,              :int ],
                      [ :order, :outside_rth,          :boolean ],
                      [ :order, :hidden,               :boolean ],
                      [ :order, :discretionary_amount, :decimal ],
                      [ :order, :good_after_time,      :string ],
                      [ :shares_allocation,            :string ],    # skip_share_allocation

                      [ :order, :fa_group,             :string ],               # fa_params
                      [ :order, :fa_method,            :string ],               # fa_params
                      [ :order, :fa_percentage,        :string ],               # fa_params
                      [ :order, :fa_profile,           :string ],               # fa_params

                      [ :order, :model_code,           :string ],
                      [ :order, :good_till_date,       :string ],
                      [ :order, :rule_80a,             :string ],
                      [ :order, :percent_offset,       :decimal ],
                      [ :order, :settling_firm,        :string ],
                      [ :order, :short_sale_slot,      :int ],        # short_sale_parameter
                      [ :order, :designated_location,  :string ],     # short_sale_parameter
                      [ :order, :exempt_code,          :int ],        # short_sale_parameter
                      [ :order, :auction_strategy,     :int ],        # auction_strategy
                      [ :order, :starting_price,       :decimal ],    # auction_strategy
                      [ :order, :stock_ref_price,      :decimal ],    # auction_strategy
                      [ :order, :delta,                :decimal ],    # auction_strategy
                      [ :order, :stock_range_lower,    :decimal ],    # auction_strategy
                      [ :order, :stock_range_upper,    :decimal ],    # auction_strategy
                      [ :order, :display_size,         :int ],
                      #@order.rth_only = @socket.read_boolean
                      [ :order, :block_order,          :boolean ],
                      [ :order, :sweep_to_fill,        :boolean ],
                      [ :order, :all_or_none,          :boolean ],
                      [ :order, :min_quantity,         :int ],
                      [ :order, :oca_type,             :int ],
                      [ :order, :etrade_only,          :boolean ],    # skip etrade only
                      [ :order, :firm_quote_only,      :boolean ],    # skip firm quote only
                      [ :order, :nbbo_price_cap,       :string ],     # skip nbbo_price_cap
                      [ :order, :parent_id,            :int ],
                      [ :order, :trigger_method,       :int ],
                      [ :order, :volatility,           :decimal ],   # vol_order_params
                      [ :order, :volatility_type,      :int ],       # vol_order_params
                      [ :order, :delta_neutral_order_type,:string ], # vol_order_params
                      [ :order, :delta_neutral_aux_price, :decimal ] # vol_order_params

      class OpenOrder

        # Accessors to make OpenOrder API-compatible with OrderStatus message

        def client_id
          order.client_id
        end

        def parent_id
          order.parent_id
        end

        def perm_id
          order.perm_id
        end

         def local_id
          order.local_id
        end

        alias order_id local_id

        def status
          order.status
        end

				def conditions
					order.conditions
				end

        # Object accessors

        def order
          @order ||= IB::Order.new @data[ :order].merge(:order_state => order_state)
        end

        def order_state
          @order_state ||= IB::OrderState.new(
              @data[ :order_state].merge(
                  :local_id  => @data[ :order ][ :local_id ],
                  :perm_id   => @data[ :order ][ :perm_id  ],
                  :parent_id => @data[ :order ][ :parent_id],
                  :client_id => @data[ :order ][ :client_id] ) )
        end

        def contract
          @contract ||= IB::Contract.build( @data[ :contract].merge(:underlying => underlying))
        end

        def underlying
          @underlying = @data[ :underlying_present ] ? IB::Underlying.new(@data[ :underlying ] ) : nil
        end

        alias under_comp underlying

        def load
          super

#          load_map [proc { | | (@data[ :order][:delta_neutral_order_type] != 'None') },
          load_map [ proc { | | filled?(@data[ :order][:delta_neutral_order_type ] ) }, # todo Testcase!
                      # As of client v.52, we may receive delta... params in openOrder
                     [ :order, :delta_neutral_con_id, :int ],
                     [ :order, :delta_neutral_settling_firm, :string ],
                     [ :order, :delta_neutral_clearing_account, :string ],
                     [ :order, :delta_neutral_clearing_intent, :string ],
                     [ :order, :delta_neutral_open_close, :string ],
                     [ :order, :delta_neutral_short_sale, :bool ],
                     [ :order, :delta_neutral_short_sale_slot, :int ],
                     [ :order, :delta_neutral_designated_location, :string ] ],  # end proc
             [ :order, :continuous_update, :int ],
             [ :order, :reference_price_type, :int ],                       ### end VolOrderParams (Python)
             [ :order, :trail_stop_price, :decimal ],   # not trail-orders. see below
             [ :order, :trailing_percent, :decimal ],
             [ :order, :basis_points, :decimal ],
             [ :order, :basis_points_type, :int ],

             [ :contract, :legs_description, :string ],

             # As of client v.55, we receive in OpenOrder for Combos:
             #    Contract.orderComboLegs Array
             #    Order.leg_prices Array
             [ :contract, :combo_legs, :array, proc do |_|
               IB::ComboLeg.new :con_id => @buffer.read_int,
                                 :ratio => @buffer.read_int,
                                :action => @buffer.read_string,
                              :exchange => @buffer.read_string,
                            :open_close => @buffer.read_int,
                       :short_sale_slot => @buffer.read_int,
                   :designated_location => @buffer.read_string,
                           :exempt_code => @buffer.read_int
             end ],
             [ :order, :leg_prices, :array, proc { |_| buffer.read_decimal } ],   #  needs testing
             [ :order, :combo_params, :hash ],
 #, proc do |_|
#		      { tag: buffer.read_string, value: buffer.read_string }  # needs testing
#  end],

             [ :order, :scale_init_level_size, :int ],
             [ :order, :scale_subs_level_size, :int ],

             [ :order, :scale_price_increment, :decimal ],
             [ proc { | | filled?( @data[ :order ][ :scale_price_increment ] ) }, # true or false
               [ :order, :scale_price_adjust_value,    :decimal ],                # if true
               [ :order, :scale_price_adjust_interval, :int ] ,
               [ :order, :scale_profit_offset,         :decimal ],
               [ :order, :scale_auto_reset,            :boolean ],
               [ :order, :scale_init_position,         :int ],
               [ :order, :scale_init_fill_qty,         :decimal ],
               [ :order, :scale_random_percent,        :boolean ] ], # end of scale price increment

             [ :order, :hedge_type, :string ],                                     # can be nil
             [ proc { | | filled?(@data[ :order ][ :hedge_type ] ) },              # true or false
               [ :order, :hedge_param, :string ] ],                                # if true

             [ :order, :opt_out_smart_routing, :boolean ],
             [ :order, :clearing_account, :string ],
             [ :order, :clearing_intent, :string ],
             [ :order, :not_held, :boolean ],

             [ :underlying_present, :boolean ],
             [ proc { | | filled?(@data[ :underlying_present ] ) },                 # true or false
              [ :underlying, :con_id, :int ],
              [ :underlying, :delta, :decimal ],
              [ :underlying, :price, :decimal ] ],                     # end of underlying present?

             # TODO: Test Order with algo_params, scale and legs!
             [ :order, :algo_strategy, :string],
             [ proc { | | filled?(@data[ :order ][ :algo_strategy ] ) },            # true of false
              [ :order, :algo_params, :hash ] ],                                    # of true

             [ :order, :solicided, :boolean ],

## whatif   serverVersion >= MIN_SERVER_VER_WHAT_IF_EXT_FIELDS
             [ :order, :what_if,   :boolean ],
             [ :order_state, :status,              :string ],
             [ :order_state, :init_margin_before,         :decimal ], #  nil unless what_if is true
             [ :order_state, :maint_margin_before,        :decimal ], #  nil unless what_if is true
             [ :order_state, :equity_with_loan_before,    :decimal ], #  nil unless what_if is true
             [ :order_state, :init_margin_change,         :decimal ], #  nil unless what_if is true
             [ :order_state, :maint_margin_change,        :decimal ], #  nil unless what_if is true
             [ :order_state, :equity_with_loan_change,    :decimal ], #  nil unless what_if is true
             [ :order_state, :init_margin_after,         :decimal ], #  nil unless what_if is true
             [ :order_state, :maint_margin_after,        :decimal ], #  nil unless what_if is true
             [ :order_state, :equity_with_loan_after,    :decimal ], #  nil unless what_if is true
             [ :order_state, :commission,          :decimal ], #  nil unless what_if is true
             [ :order_state, :min_commission,      :decimal ], #  nil unless what_if is true
             [ :order_state, :max_commission,      :decimal ], #  nil unless what_if is true
             [ :order_state, :commission_currency, :string ],  #  nil unless what_if is true
             [ :order_state, :warning_text,        :string ],  #  nil unless what_if is true


             [ :order, :random_size, :boolean ],
             [ :order, :random_price, :boolean ],

             ## todo: ordertype = PEG BENCH  --  -> test!
             [ proc { @data[ :order ][ :order_type ] == 'PEG BENCH' },               # true of false
               [ :order, :reference_contract_id,            :int ],
               [ :order, :is_pegged_change_amount_decrease, :bool ],
               [ :order, :pegged_change_amount,             :decimal ],
               [ :order, :reference_change_amount,          :decimal ],
               [ :order, :reference_exchange_id, :string ] ],    #  end special parameters PEG BENCH

             [ :order , :conditions, :array, proc {  IB::OrderCondition.make_from( @buffer ) } ],
             [ proc { !@data[ :order ][ :conditions ].blank?  },                     # true or false
               [ :order, :conditions_ignore_rth, :bool ],
               [ :order, :conditions_cancel_order,:bool ] ],
             #AdjustedOrderParams
             [ :order, :adjusted_order_type,        :string ],
             [ :order, :trigger_price,              :decimal ],
             [ :order, :trail_stop_price,           :decimal ],	    #  Traillimit orders
             [ :order, :limit_price_offset,         :decimal ],
             [ :order, :adjusted_stop_price,        :decimal ],
             [ :order, :adjusted_stop_limit_price,  :decimal ],
             [ :order, :adjusted_trailing_amount,   :decimal ],
             [ :order, :adjustable_trailing_unit,   :int ],
             # SoftDollarTier
             [ :order, :soft_dollar_tier_name,         :string_not_null ],
             [ :order, :soft_dollar_tier_value,        :string_not_null ],
             [ :order, :soft_dollar_tier_display_name, :string_not_null ],
             [ :order, :cash_qty,  :decimal ],
	  #  [ :order, :mifid_2_decision_maker, :string_not_null ],   ## correct appearance of fields below
		# [ :order, :mifid_2_decision_algo, :string_not_null ],		##  is not tested yet
		# [ :order, :mifid_2_execution_maker, :string ],
 #	 [ :order, :mifid_2_execution_algo, :string_not_null ],
             [ :order, :dont_use_auto_price_for_hedge,   :bool ],
             [ :order, :is_O_ms_container,               :bool ],
             [ :order, :discretionary_up_to_limit_price, :bool ],
             [ :order, :use_price_management_algo,       :bool ],
             [ :order, :duration,                        :int ],
             [ :order, :post_to_ats,                     :int ],
             [ :order, :auto_cancel_parent,              :bool ]
         # not implemented now > Server Version 170
         # PEGBEST_PEGMID_OFFSETS:
         # [:order, :min_trade_qty, :int ],
         # [:order, :min_compete_size, :int ],
         # [:order, :compete_against_best_offset, :decimal],
         # [:order, :mid_offset_at_whole, :decimal ],
         # [:order, :mid_offset_at_half, :decimal ]
         # not implemented now > Server Version 183
         # [:order, :customer_account, :string]
         # not implemented now > Server Version 184
         # [:order, :professional_customer, :bool]

        end

        # Check if given value was set by TWS to something vaguely "positive"
        def filled? value
#	  puts "filled: #{value.class} --> #{value.to_s}"
          case value
            when String
              (!value.empty?)# && (value != :none) && (value !='None')
            when Float, Integer, BigDecimal
              value > 0
            else
              !!value # to_bool
          end
        end

        def to_human
          "<OpenOrder: #{contract.to_human} #{order.to_human}>"
        end

      end # class OpenOrder
    end # module Incoming
  end # module Messages
end # module IB
