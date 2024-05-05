module IB
  module Messages
    module Outgoing
      extend Messages # def_message macros

      PlaceOrder = def_message [3]	## ServerVersion > 145 && < 163:  def_message[ 3,45 ]
      # ## server-version is not known at compilation time
      # ## Method call has to be replaced then
      # ## Max-Client_ver --> 144!!

      class PlaceOrder
        def encode
          server_version = Connection.current.server_version
          requested_version = server_version < KNOWN_SERVERS[:min_server_ver_not_held] ? 27 : 45
          order = @data[:order]
          contract = @data[:contract]

          error 'contract has to be specified' unless contract.is_a? IB::Contract

          # send place order msg
          fields = [3]
          fields.push(requested_version) if server_version < KNOWN_SERVERS[:min_server_ver_order_container]
          fields.push(@data[:local_id])

          # send contract fields
          if server_version >= KNOWN_SERVERS[:min_server_ver_place_order_conid]
            fields.push(contract.con_id)
          end

          fields += [
            contract.symbol,
            contract[:sec_type],
            contract.expiry,
            contract.strike.is_a?(Numeric) && contract.strike.positive? ? contract.strike : contract.strike.negative? ? 0 : '',
            contract[:right],
            contract.multiplier,
            contract.exchange,
            contract.primary_exchange,
            contract.currency,
            contract.local_symbol
          ]

          if server_version >= KNOWN_SERVERS[:min_server_ver_trading_class]
            fields.push(contract.trading_class)
          end

          if server_version >= KNOWN_SERVERS[:min_server_ver_sec_id_type]
            fields += [
              contract.sec_id_type,
              contract.sec_id
            ]
          end

          # send main order fields
          fields.push(if order.side == :short
                        'SSHORT'
                      else
                        order.side == :short_exempt ? 'SSHORTX' : order.side.to_sup
                      end)
          if server_version >= KNOWN_SERVERS[:min_server_ver_fractional_positions]
            fields.push(order.total_quantity.to_d)
          else
            fields.push(order.total_quantity.to_i)
          end
          fields.push(order[:order_type]) # Internal code, 'LMT' instead of :limit
          if server_version < KNOWN_SERVERS[:min_server_ver_order_combo_legs_price]
            fields.push(order.limit_price || 0)
          else
            fields.push(order.limit_price || '')
          end
          if server_version < KNOWN_SERVERS[:min_server_ver_trailing_percent]
            fields.push(order.aux_price || 0)
          else
            fields.push(order.aux_price || '')

            # extended order fields
            fields += [
              order[:tif],
              order.oca_group,
              order.account,
              order.open_close.to_sup[0],
              order[:origin],  # translates :customer, :firm  to 0,1
              order.order_ref,
              order.transmit,
              order.parent_id, # srv v4 and above
              order.block_order || false, # srv v5 and above
              order.sweep_to_fill || false, # srv v5 and above
              order.display_size, # srv v5 and above
              order[:trigger_method], # srv v5 and above
              order.outside_rth || false, # was: ignore_rth # srv v5 and above
              order.hidden || false
            ] # srv v7 and above
          end

          # Send combo legs for BAG requests (srv v8 and above)
          if contract.bag?
            fields.push(combo_legs.size)
            fields += combo_legs.map do |the_leg|
              array = [
                the_leg.con_id,
                the_leg.ratio,
                the_leg.side.to_sup,
                the_leg.exchange,
                the_leg[:open_close],
                the_leg[:short_sale_slot],
                the_leg.designated_location,
              ]
              array.push(the_leg.exempt_code) if server_version >= KNOWN_SERVERS[:min_server_ver_sshortx_old]
              array
            end.flatten

            # TODO: order_combo_leg?
            if server_version >= KNOWN_SERVERS[:min_server_ver_order_combo_legs_price]
              fields.push(contract.combo_legs.size)
              fields += contract.combo_legs.map { |leg| leg.price || '' }
            end

            # TODO: smartComboRoutingParams
            if server_version >= KNOWN_SERVERS[:min_server_ver_smart_combo_routing_params]
              fields.push(order.combo_params.size)
              fields += order.combo_params.to_a
            end
          end

          fields += [
            '', # send deprecated sharesAllocation field
            order.discretionary_amount,
            order.good_after_time,
            order.good_till_date,
            order.fa_group,
            order.fa_method,
            order.fa_percentage
          ]
          if server_version < KNOWN_SERVERS[:min_server_ver_fa_profile_desupport]
            fields.push('') # send deprecated faProfile field
          end

          if server_version >= KNOWN_SERVERS[:min_server_ver_models_support]
            fields.push(order.model_code || '')
          end

          fields += [
            order[:short_sale_slot] || 0, # 0 only for retail, 1 or 2 for institution  (Institutional)
            order.designated_location # only populate when short_sale_slot == 2    (Institutional)
          ]

          fields.push(order.exempt_code) if server_version >= KNOWN_SERVERS[:min_server_ver_sshortx_old]

          fields.push(order[:oca_type])
          fields += [
            order[:rule_80a], # .to_sup[0..0],
            order.settling_firm,
            order.all_or_none || false,
            order.min_quantity || '',
            order.percent_offset || '',
            false, # was: order.etrade_only || false,  desupported in TWS > 981
            false, # was: order.firm_quote_only || false,    desupported in TWS > 981
            '', ## desupported in TWS > 981, too. maybe we have to insert a hard-coded "" here
            order[:auction_strategy], # AUCTION_MATCH, AUCTION_IMPROVEMENT, AUCTION_TRANSPARENT
            order.starting_price || '',
            order.stock_ref_price || '',
            order.delta || '',
            order.stock_range_lower || '',
            order.stock_range_upper || '',
            order.override_percentage_constraints || false,
            order.volatility || '',
            order.volatility ? order[:volatility_type] || 2 : '',
            order[:delta_neutral_order_type],
            order.delta_neutral_aux_price || ''
          ]

          if order.delta_neutral_order_type && order.delta_neutral_order_type != :none
            if server_version >= KNOWN_SERVERS[:min_server_ver_delta_neutral_conid]
              fields += [
                order.delta_neutral_con_id,
                order.delta_neutral_settling_firm,
                order.delta_neutral_clearing_account,
                order[:delta_neutral_clearing_intent]
              ]
            end

            if server_version >= KNOWN_SERVERS[:min_server_ver_delta_neutral_open_close]
              fields += [
                order.delta_neutral_open_close,
                order.delta_neutral_short_sale,
                order.delta_neutral_short_sale_slot,
                order.delta_neutral_designated_location
              ]
            end
          end

          fields += [
            order.continuous_update,
            order[:reference_price_type] || '',
            order.trail_stop_price || ''

          ]

          fields.push(order.trailing_percent || '') if server_version >= KNOWN_SERVERS[:min_server_ver_trailing_percent]

          fields += if server_version >= KNOWN_SERVERS[:min_server_ver_scale_orders2]
                      [
                        order.scale_init_level_size || '',
                        order.scale_subs_level_size || ''
                      ]
                    else
                      [
                        '',
                        order.scale_init_level_size || ''
                      ]
                    end

          fields.push(order.scale_price_increment || '')

          if server_version >= KNOWN_SERVERS[:min_server_ver_scale_orders3] && order.scale_price_increment &&
             order.scale_price_increment > 0
            fields += [
              order.scale_price_adjust_value || '',
              order.scale_price_adjust_interval || '',
              order.scale_profit_offset || '',
              order.scale_auto_reset, #  default: false,
              order.scale_init_position || '',
              order.scale_init_fill_qty || '',
              order.scale_random_percent # default: false,
            ]
          end

          if server_version >= KNOWN_SERVERS[:min_server_ver_scale_table]
            fields += [
              order.scale_table,
              order.active_start_time,
              order.active_stop_time
            ]
          end
          if server_version >= KNOWN_SERVERS[:min_server_ver_hedge_orders]
            fields.push(order.hedge_type)
            fields += order.hedge_param if order.hedge_param
          end

          if server_version >= KNOWN_SERVERS[:min_server_ver_opt_out_smart_routing]
            fields.push(order.opt_out_smart_routing)
          end

          if server_version >= KNOWN_SERVERS[:min_server_ver_pta_orders]
            fields += [
              order.clearing_account,
              order.clearing_intent
            ]
          end

          fields.push(order.not_held) if server_version >= KNOWN_SERVERS[:min_server_ver_not_held]

          if server_version >= KNOWN_SERVERS[:min_server_ver_delta_neutral]
            fields += contract.serialize_under_comp
          end

          if server_version >= KNOWN_SERVERS[:min_server_ver_algo_orders]
            fields += order.serialize_algo
          end
          if server_version >= KNOWN_SERVERS[:min_server_ver_algo_id]
            fields.push(order.algo_id)
          end

          fields.push(order.what_if)
          fields.push(order.serialize_misc_options) if server_version >= KNOWN_SERVERS[:min_server_ver_linking]
          fields.push(order.solicided) if server_version >= KNOWN_SERVERS[:min_server_ver_order_solicited]
          if server_version >= KNOWN_SERVERS[:min_server_ver_randomize_size_and_price]
            fields += [
              order.random_size,
              order.random_price
            ]
          end

          if server_version >= KNOWN_SERVERS[:min_server_ver_pegged_to_benchmark]
            if order[:type] == 'PEG BENCH'
              fields += [
                order.reference_contract_id,
                order.is_pegged_change_amount_decrease,
                order.pegged_change_amount,
                order.reference_change_amount,
                order.reference_exchange_id
              ]
            end

            fields += order.serialize_conditions
            fields += [
              order.adjusted_order_type,
              order.trigger_price,
              order.limit_price_offset,
              order.adjusted_stop_price,
              order.adjusted_stop_limit_price,
              order.adjusted_trailing_amount,
              order.adjustable_trailing_unit
            ]
          end

          fields.push(order.ext_operator) if server_version >= KNOWN_SERVERS[:min_server_ver_ext_operator]

          if server_version >= KNOWN_SERVERS[:min_server_ver_soft_dollar_tier]
            fields += [
              order.soft_dollar_tier_name,
              order.soft_dollar_tier_value
            ]
          end

          fields.push(order.cash_qty) if server_version >= KNOWN_SERVERS[:min_server_ver_cash_qty]

          if server_version >= KNOWN_SERVERS[:min_server_ver_decision_maker]
            fields += [order.mifid_2_decision_maker, order.mifid_2_decision_algo]
          end
          if server_version >= KNOWN_SERVERS[:min_server_ver_mifid_execution]
            fields += [order.mifid_2_execution_maker, order.mifid_2_execution_algo]
          end

          if server_version >= KNOWN_SERVERS[:min_server_ver_auto_price_for_hedge]
            fields.push(order.dont_use_auto_price_for_hedge)
          end

          fields.push(order.is_O_ms_container) if server_version >= KNOWN_SERVERS[:min_server_ver_order_container]

          if server_version >= KNOWN_SERVERS[:min_server_ver_d_peg_orders]
            fields.push(order.discretionary_up_to_limit_price)
          end

          if server_version >= KNOWN_SERVERS[:min_server_ver_price_mgmt_algo]
            if order.use_price_management_algo.nil?
              fields.push('')
            else
              fields.push(order.use_price_management_algo)
            end
          end

          if server_version >= KNOWN_SERVERS[:min_server_ver_duration]
            fields.push(order.duration)
          end

          if server_version >= KNOWN_SERVERS[:min_server_ver_post_to_ats]
            fields.push(order.post_to_ats)
          end

          if server_version >= KNOWN_SERVERS[:min_server_ver_auto_cancel_parent]
            fields.push(order.auto_cancel_parent)
          end

          if server_version >= KNOWN_SERVERS[:min_server_ver_advanced_order_reject]
            fields.push(order.advanced_order_reject)
          end

          if server_version >= KNOWN_SERVERS[:min_server_ver_manual_order_time]
            fields.push(order.manual_order_time)
          end

          if server_version >= KNOWN_SERVERS[:min_server_ver_pegbest_pegmid_offsets]
            send_mid_offsets = false

            fields.push(order.min_trade_qty) if contract.exchange == 'IBKRATS'
            if ['PEG BEST', 'PEGBEST'].include?(order.type)
              fields += [
                order.min_compete_size,
                order.compete_against_best_offset
              ]
              send_mid_offsets = true if order.compete_against_best_offset.nil? # TODO: float max?
            elsif ["PEG BEST", "PEGBEST"].include?(order.type)
              send_mid_offsets = true
            end

            if send_mid_offsets
              fields += [
                order.mid_offset_at_whole,
                order.mid_offset_at_half
              ]
            end
          end

          if server_version >= KNOWN_SERVERS[:min_server_ver_customer_account]
            fields.push(order.customer_account)
          end

          if server_version >= KNOWN_SERVERS[:min_server_ver_professional_customer]
            fields.push(order.professional_account)
          end

          fields
        end
      end
    end
  end
end
