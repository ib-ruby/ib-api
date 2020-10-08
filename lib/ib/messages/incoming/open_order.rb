module IB
  module Messages
    module Incoming
      using IBSupport
      # OpenOrder is the longest message with complex processing logics
      OpenOrder =
        def_message [5, 34],	# updated to v. 34 according to python (decoder.py processOpenOrder)
                    %i[order local_id int],
                    %i[contract contract], # read standard-contract
                    # [ con_id, symbol,. sec_type, expiry, strike, right, multiplier,
                    # 	exchange, currency, local_symbol, trading_class ]
                    %i[order action string],
                    %i[order total_quantity decimal],
                    %i[order order_type string],
                    %i[order limit_price decimal],
                    %i[order aux_price decimal],
                    %i[order tif string],
                    %i[order oca_group string],
                    %i[order account string],
                    %i[order open_close string],
                    %i[order origin int],
                    %i[order order_ref string],
                    %i[order client_id int],
                    %i[order perm_id int],
                    %i[order outside_rth boolean], # (@socket.read_int == 1)
                    %i[order hidden boolean], # (@socket.read_int == 1)
                    %i[order discretionary_amount decimal],
                    %i[order good_after_time string],
                    %i[shares_allocation string], # deprecated! field
                    %i[order fa_group string],
                    %i[order fa_method string],
                    %i[order fa_percentage string],
                    %i[order fa_profile string],
                    %i[order model_code string],
                    %i[order good_till_date string],
                    %i[order rule_80a string],
                    %i[order percent_offset decimal],
                    %i[order settling_firm string],
                    %i[order short_sale_slot int],
                    %i[order designated_location string],
                    %i[order exempt_code int],
                    %i[order auction_strategy int],
                    %i[order starting_price decimal],
                    %i[order stock_ref_price decimal],
                    %i[order delta decimal],
                    %i[order stock_range_lower decimal],
                    %i[order stock_range_upper decimal],
                    %i[order display_size int],
                    # @order.rth_only = @socket.read_boolean
                    %i[order block_order boolean],
                    %i[order sweep_to_fill boolean],
                    %i[order all_or_none boolean],
                    %i[order min_quantity int],
                    %i[order oca_type int],
                    %i[order etrade_only boolean],
                    %i[order firm_quote_only boolean],
                    %i[order nbbo_price_cap decimal],
                    %i[order parent_id int],
                    %i[order trigger_method int],
                    %i[order volatility decimal],
                    %i[order volatility_type int],
                    %i[order delta_neutral_order_type string],
                    %i[order delta_neutral_aux_price decimal]

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
          @order ||= IB::Order.new @data[:order].merge(order_state: order_state)
        end

        def order_state
          @order_state ||= IB::OrderState.new(
            @data[:order_state].merge(
              local_id: @data[:order][:local_id],
              perm_id: @data[:order][:perm_id],
              parent_id: @data[:order][:parent_id],
              client_id: @data[:order][:client_id]
            )
          )
        end

        def contract
          @contract ||= IB::Contract.build(
            @data[:contract].merge(underlying: underlying)
          )
        end

        def underlying
          @underlying = @data[:underlying_present] ? IB::Underlying.new(@data[:underlying]) : nil
        end

        alias under_comp underlying

        def load
          super

          #          load_map [proc { | | (@data[:order][:delta_neutral_order_type] != 'None') },
          load_map [proc { filled?(@data[:order][:delta_neutral_order_type]) }, # TODO: Testcase!
                    # As of client v.52, we may receive delta... params in openOrder
                    %i[order delta_neutral_con_id int],
                    %i[order delta_neutral_settling_firm string],
                    %i[order delta_neutral_clearing_account string],
                    %i[order delta_neutral_clearing_intent string],
                    %i[order delta_neutral_open_close string],
                    %i[order delta_neutral_short_sale bool],
                    %i[order delta_neutral_short_sale_slot int],
                    %i[order delta_neutral_designated_location string]], # end proc
                   %i[order continuous_update int],
                   %i[order reference_price_type int],
                   %i[order trail_stop_price decimal], # not trail-orders. see below
                   %i[order trailing_percent decimal],
                   %i[order basis_points decimal],
                   %i[order basis_points_type int],
                   %i[contract legs_description string],
                   # As of client v.55, we receive in OpenOrder for Combos:
                   #    Contract.orderComboLegs Array
                   #    Order.leg_prices Array
                   [:contract, :combo_legs, :array, proc do |_|
                     IB::ComboLeg.new con_id: @buffer.read_int,
                                      ratio: @buffer.read_int,
                                      action: @buffer.read_string,
                                      exchange: @buffer.read_string,
                                      open_close: @buffer.read_int,
                                      short_sale_slot: @buffer.read_int,
                                      designated_location: @buffer.read_string,
                                      exempt_code: @buffer.read_int
                   end],
                   [:order, :leg_prices, :array, proc { |_| buffer.read_decimal }], #  needs testing
                   %i[order combo_params hash],
                   # , proc do |_|
                   #		      { tag: buffer.read_string, value: buffer.read_string }  # needs testing
                   #  end],
                   %i[order scale_init_level_size int],
                   %i[order scale_subs_level_size int],
                   %i[order scale_price_increment decimal],
                   [proc { filled?(@data[:order][:scale_price_increment]) },
                    # As of client v.54, we may receive scale order fields
                    %i[order scale_price_adjust_value decimal],
                    %i[order scale_price_adjust_interval int],
                    %i[order scale_profit_offset decimal],
                    %i[order scale_auto_reset boolean],
                    %i[order scale_init_position int],
                    %i[order scale_init_fill_qty decimal],
                    %i[order scale_random_percent boolean]],
                   %i[order hedge_type string],
                   [proc { filled?(@data[:order][:hedge_type]) },
                    # As of client v.49/50, we can receive hedgeType, hedgeParam
                    %i[order hedge_param string]],
                   %i[order opt_out_smart_routing boolean],
                   %i[order clearing_account string],
                   %i[order clearing_intent string],
                   %i[order not_held boolean],
                   %i[underlying_present boolean],
                   [proc { filled?(@data[:underlying_present]) },
                    %i[underlying con_id int],
                    %i[underlying delta decimal],
                    %i[underlying price decimal]],
                   # TODO: Test Order with algo_params, scale and legs!
                   %i[order algo_strategy string],
                   [proc { filled?(@data[:order][:algo_strategy]) },
                    %i[order algo_params hash]],
                   %i[order solicided boolean],
                   %i[order what_if boolean],
                   %i[order_state status string],
                   # IB uses weird String with Java Double.MAX_VALUE to indicate no value here
                   %i[order_state init_margin decimal], # :string],
                   %i[order_state maint_margin decimal], # :string],
                   %i[order_state equity_with_loan decimal], # :string],
                   %i[order_state commission decimal], # May be nil!
                   %i[order_state min_commission decimal], # May be nil!
                   %i[order_state max_commission decimal], # May be nil!
                   %i[order_state commission_currency string],
                   %i[order_state warning_text string],
                   %i[order random_size boolean],
                   %i[order random_price boolean],
                   ## todo: ordertype = PEG BENCH  --  -> test!
                   [proc { @data[:order][:order_type] == 'PEG BENCH' },
                    %i[order reference_contract_id int],
                    %i[order is_pegged_change_amount_decrease bool],
                    %i[order pegged_change_amount decimal],
                    %i[order reference_change_amount decimal],
                    %i[order reference_exchange_id string]],
                   [:order, :conditions, :array, proc { IB::OrderCondition.make_from(@buffer) }],
                   [proc { !@data[:order][:conditions].blank? },
                    %i[order conditions_ignore_rth bool],
                    %i[order conditions_cancel_order bool]],
                   %i[order adjusted_order_type string],
                   %i[order trigger_price decimal],
                   %i[order trail_stop_price decimal], # cpp -source: Traillimit orders
                   %i[order adjusted_stop_limit_price decimal],
                   %i[order adjusted_trailing_amount decimal],
                   %i[order adjustable_trailing_unit int],
                   %i[order soft_dollar_tier_name string_not_null],
                   %i[order soft_dollar_tier_value string_not_null],
                   %i[order soft_dollar_tier_display_name string_not_null],
                   %i[order cash_qty decimal],
                   %i[order mifid_2_decision_maker string_not_null], ## correct appearance of fields below
                   %i[order mifid_2_decision_algo string_not_null],	##  is not tested yet
                   %i[order mifid_2_execution_maker string],
                   %i[order mifid_2_execution_algo string_not_null],
                   %i[order dont_use_auto_price_for_hedge string],
                   %i[order is_O_ms_container bool],
                   %i[order discretionary_up_to_limit_price decimal]
        end

        # Check if given value was set by TWS to something vaguely "positive"
        def filled? value
          #	  puts "filled: #{value.class} --> #{value.to_s}"
          case value
          when String
            !value.empty? # && (value != :none) && (value !='None')
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
