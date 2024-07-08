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
          fields = [ super ,
                    contract.serialize_short(:primary_exchange, :sec_id_type),
                    order.serialize_main_order_fields,
                    order.serialize_extended_order_fields,
                    order.serialize_combo_legs,
                    order.serialize_auxilery_order_fields # incluing advisory order fields
                    ]

          if server_version >= KNOWN_SERVERS[:min_server_ver_models_support]  # 103
            fields.push(order.model_code )
          end

          fields += [
            order[:short_sale_slot] , # 0 only for retail, 1 or 2 for institution  (Institutional)
            order.designated_location # only populate when short_sale_slot == 2    (Institutional)
          ]

          fields.push(order.exempt_code) #if server_version >= KNOWN_SERVERS[:min_server_ver_sshortx_old]

          fields.push(order[:oca_type])
          fields += [
            order[:rule_80a], # .to_sup[0..0],
            order.settling_firm,
            order.all_or_none,
            order.min_quantity,
            order.percent_offset,
            false, # etrade_only ,  desupported in TWS > 981
            false, # firm_quote_only ,    desupported in TWS > 981
            '', ## desupported in TWS > 981, too.
            order[:auction_strategy], # one of: AUCTION_MATCH, AUCTION_IMPROVEMENT, AUCTION_TRANSPARENT
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

          fields.push(order.not_held)

          fields << contract.serialize_under_comp
          fields << order.serialize_algo

          fields.push(order.algo_id)
          fields.push(order.what_if)
          fields.push(order.serialize_misc_options)
          fields.push(order.solicided)
          fields << [ order.random_size, order.random_price ]

          fields << order.serialize_pegged_order_fields
          fields << order.serialize_conditions
          fields << [
              order.adjusted_order_type,
              order.trigger_price,
              order.limit_price_offset,
              order.adjusted_stop_price,
              order.adjusted_stop_limit_price,
              order.adjusted_trailing_amount,
              order.adjustable_trailing_unit
            ]

          fields.push(order.ext_operator) if server_version >= KNOWN_SERVERS[:min_server_ver_ext_operator] #  105

          fields << order.serialize_soft_dollar_tier

          fields.push(order.cash_qty) if server_version >= KNOWN_SERVERS[:min_server_ver_cash_qty] # 111

          fields << order.serialize_mifid_order_fields

          if server_version >= KNOWN_SERVERS[:min_server_ver_auto_price_for_hedge]  # 141
            fields.push(order.dont_use_auto_price_for_hedge)
          end

          fields.push(order.is_O_ms_container) if server_version >= KNOWN_SERVERS[:min_server_ver_order_container] # 145

          if server_version >= KNOWN_SERVERS[:min_server_ver_d_peg_orders]  # 148
            fields.push(order.discretionary_up_to_limit_price)
          end

          if server_version >= KNOWN_SERVERS[:min_server_ver_price_mgmt_algo] # 151
            fields.push(order.use_price_management_algo)
          end

          if server_version >= KNOWN_SERVERS[:min_server_ver_duration]  # 158
            fields.push(order.duration)
          end

          if server_version >= KNOWN_SERVERS[:min_server_ver_post_to_ats]  # 160
            fields.push(order.post_to_ats)
          end

          if server_version >= KNOWN_SERVERS[:min_server_ver_auto_cancel_parent] # 162
            fields.push(order.auto_cancel_parent)
          end

          if server_version >= KNOWN_SERVERS[:min_server_ver_advanced_order_reject] # 166
            fields.push(order.advanced_order_reject)
          end

          if server_version >= KNOWN_SERVERS[:min_server_ver_manual_order_time] # 169
            fields.push(order.manual_order_time)
          end

          fields << order.serialize_peg_best_and_mid

          if server_version >= KNOWN_SERVERS[:min_server_ver_customer_account]  # 183
            fields.push(order.customer_account)
          end

          if server_version >= KNOWN_SERVERS[:min_server_ver_professional_customer]  # 184
            fields.push(order.professional_account)
          end

          fields
        end
      end
    end
  end
end
