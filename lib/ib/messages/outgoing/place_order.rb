module IB
  module Messages
    module Outgoing
      extend Messages # def_message macros

      PlaceOrder = def_message [ 3,0	]

      class PlaceOrder
        def encode
          order = @data[:order]
          contract = @data[:contract]

          error 'contract has to be specified' unless contract.is_a? IB::Contract

          # send place order msg
          fields = [ super ]
          fields << contract.serialize_short(:primary_exchange, :sec_id_type)
          fields << order.serialize_main_order_fields
          fields << order.serialize_extended_order_fields
          fields << order.serialize_combo_legs
          fields << order.serialize_auxilery_order_fields # incluing advisory order fields

          if server_version >= KNOWN_SERVERS[:min_server_ver_models_support]
            fields.push(order.model_code )
          end

          fields += [
            order[:short_sale_slot] , # 0 only for retail, 1 or 2 for institution  (Institutional)
            order.designated_location # only populate when short_sale_slot == 2    (Institutional)
          ]

          fields.push(order.exempt_code) if server_version >= KNOWN_SERVERS[:min_server_ver_sshortx_old]

          fields.push(order[:oca_type])
          fields += [
            order[:rule_80a], # .to_sup[0..0],
            order.settling_firm,
            order.all_or_none,
            order.min_quantity,
            order.percent_offset,
            false, # was: order.etrade_only || false,  desupported in TWS > 981
            false, # was: order.firm_quote_only || false,    desupported in TWS > 981
            '', ## desupported in TWS > 981, too. maybe we have to insert a hard-coded "" here
            order[:auction_strategy], # AUCTION_MATCH, AUCTION_IMPROVEMENT, AUCTION_TRANSPARENT
            order.serialize_advanced_option_order_fields,
            order.override_percentage_constraints,
            order.serialize_volatility_order_fields,
            order.serialize_delta_neutral_order_fields
          ]

          fields += [
            order.continuous_update,
            order[:reference_price_type] ,
            order.trail_stop_price,
            order.trailing_percent
          ]

          fields << order.serialize_scale_order_fields

          fields.push order.hedge_type
          fields.push order.hedge_param  # default is [] --> omitted if left default
          fields.push order.opt_out_smart_routing

          fields.push  order.clearing_account
          fields.push  order.clearing_intent

          fields.push(order.not_held) # if server_version >= KNOWN_SERVERS[:min_server_ver_not_held] #44

          if server_version >= KNOWN_SERVERS[:min_server_ver_delta_neutral]  # 40
            fields += contract.serialize_under_comp
          end

          if server_version >= KNOWN_SERVERS[:min_server_ver_algo_orders]  # 41
            fields += order.serialize_algo
          end
          if server_version >= KNOWN_SERVERS[:min_server_ver_algo_id]   # 71 
            fields.push(order.algo_id)
          end

          fields.push(order.what_if)
          fields.push(order.serialize_misc_options) # if server_version >= KNOWN_SERVERS[:min_server_ver_linking] # 70
          fields.push(order.solicided) #if server_version >= KNOWN_SERVERS[:min_server_ver_order_solicited] # 73
#          if server_version >= KNOWN_SERVERS[:min_server_ver_randomize_size_and_price]   # 76
            fields += [
              order.random_size,
              order.random_price
            ]
#          end

          fields << order.serialize_pegged_order_fields
#          if server_version >= KNOWN_SERVERS[:min_server_ver_pegged_to_benchmark]  #  102
#            if order[:order_type] == 'PEG BENCH'
#              fields += [
#                order.reference_contract_id,
#                order.is_pegged_change_amount_decrease,
#                order.pegged_change_amount,
#                order.reference_change_amount,
#                order.reference_exchange_id
#              ]
#            end
#
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
#          end

          fields.push(order.ext_operator) if server_version >= KNOWN_SERVERS[:min_server_ver_ext_operator]

          fields << order.serialize_soft_dollar_tier

          fields.push(order.cash_qty) if server_version >= KNOWN_SERVERS[:min_server_ver_cash_qty] # 111

          fields << order.serialize_mifid_order_fields

          if server_version >= KNOWN_SERVERS[:min_server_ver_auto_price_for_hedge]
            fields.push(order.dont_use_auto_price_for_hedge)
          end

          fields.push(order.is_O_ms_container) if server_version >= KNOWN_SERVERS[:min_server_ver_order_container]

          if server_version >= KNOWN_SERVERS[:min_server_ver_d_peg_orders]
            fields.push(order.discretionary_up_to_limit_price)
          end

          if server_version >= KNOWN_SERVERS[:min_server_ver_price_mgmt_algo]
            fields.push(order.use_price_management_algo)
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

          fields << order.serialize_peg_best_and_mid

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
