module IB
  module Messages
    module Outgoing
      extend Messages # def_message macros

      # Data format is { :id => local_id,
      #                  :contract => Contract,
      #                  :order => Order }
      PlaceOrder = def_message [ 3,0 ]

      class PlaceOrder
        def encode

        # lamba's to include order fields dependend of the server version provided
        include_model_code = -> (m) { if server_version >= KNOWN_SERVERS[ :min_server_ver_models_support ] then m else [] end }
        include_ext_operator = -> (e) { if server_version >= KNOWN_SERVERS[ :min_server_ver_ext_operator ] then e else [] end }
        include_cash_qty = -> (c) { if server_version >= KNOWN_SERVERS[ :min_server_ver_cash_qty ] then c else [] end  }
        include_auto_price_for_hedge = -> (a) { if server_version >= KNOWN_SERVERS[ :min_server_ver_auto_price_for_hedge ] then a else [] end  }
        include_order_container = -> (o) { if server_version >= KNOWN_SERVERS[ :min_server_ver_order_container] then o else [] end  }
        include_d_peg_order = -> (d) { if server_version >= KNOWN_SERVERS[ :min_server_ver_d_peg_orders ] then d else [] end  }
        include_price_mgmt_algo = -> (p) { if server_version >= KNOWN_SERVERS[ :min_server_ver_price_mgmt_algo ]then p else [] end  }
        include_duration = -> (d) { if server_version >= KNOWN_SERVERS[ :min_server_ver_duration ]then d else [] end  }
        include_ats = -> (a)  { if server_version >= KNOWN_SERVERS[ :min_server_ver_post_to_ats ]then a else [] end  }
        include_auto_cancel_parent = -> (a) { if server_version >= KNOWN_SERVERS[ :min_server_ver_auto_cancel_parent ] then a else [] end }
        include_manual_order_time = -> (m) {  if server_version >= KNOWN_SERVERS[ :min_server_ver_manual_order_time ] then m else [] end }
        include_advanced_reject =  -> (a){ if server_version >= KNOWN_SERVERS[ :min_server_ver_advanced_order_reject ] then a else [] end }
        include_customer_account = -> (c) { if  server_version >= KNOWN_SERVERS[  :min_server_ver_customer_account ] then c else [] end }
        include_professional_customer = -> (p) { if  server_version >= KNOWN_SERVERS[ :min_server_ver_professional_customer ] then p else [] end }

          order = @data[ :order ]
          contract = @data[ :contract ]

          error "contract has to be specified" unless contract.is_a? IB::Contract

# -------------------------- start here -----------------------------------------
# build an array of order values ready to be transmitted to the tws ( after flattening )
#
         [ super,
           contract.serialize_short( :primary_exchange, :sec_id_type ),
           order.serialize_main_order_fields,
           order.serialize_extended_order_fields,
# legs
           [  contract.serialize_legs( :extended ),
           if contract.bag?
             [
               ## Support for per-leg prices in Order
               [contract.combo_legs.size] + contract.combo_legs.map { |_| nil }, #(&:price) ,
               ## Support for combo routing params in Order
               order.combo_params.empty? ? 0 : [order.combo_params.size] + order.combo_params.to_a
             ]
          else
            [ "do not include" ]
          end ],
          order.serialize_auxilery_order_fields, # incluing advisory order fields
# regulatory order fields
          [
           include_model_code[ order.model_code ],
           order[:short_sale_slot] , # 0 only for retail, 1 or 2 for institution  (Institutional)
           order.designated_location, # only populate when short_sale_slot == 2    (Institutional)
           order.exempt_code,
           order[:oca_type],
           order[:rule_80a], #.to_sup[0..0],
           order.settling_firm ],
# algo order fields -1-   (8)
           [ order.all_or_none,
           order.min_quantity ,
           order.percent_offset,
           false, # was: order.etrade_only || false,  desupported in TWS > 981
           false, # was: order.firm_quote_only || false,    desupported in TWS > 981
           false, # was  order.nbbo_price_cap || "", ## desupported in TWS > 981
           order[:auction_strategy],
           order.starting_price,
           order.stock_ref_price,
           order.delta,
           order.stock_range_lower,
           order.stock_range_upper,
           order.override_percentage_constraints,
           order.serialize_volatility_order_fields
           ],

           order.serialize_delta_neutral_order_fields,  # (9)

#        Volatility orders  (10)
          [
           order.continuous_update,
           order[:reference_price_type],
          ],
#         trailing orders  (11)
           #
           [
            order.trail_stop_price,
            order.trailing_percent,
           ],

           order.serialize_scale_order_fields,  # (12)

# Support for hedgeType   (13)
          [
            order.hedge_type,
            order.hedge_param
          ],

        order.opt_out_smart_routing,

        order.clearing_account ,
        order.clearing_intent ,
        order.not_held ,
        contract.serialize_under_comp,
        order.serialize_algo(),
        order.what_if,
        order.serialize_misc_options,
        order.solicided,
        order.random_size,
        order.random_price,
        order.serialize_pegged_order_fields,
        order.serialize_conditions ,
        order.adjusted_order_type ,
        order.trigger_price ,
        order.limit_price_offset ,
        order.adjusted_stop_price ,
        order.adjusted_stop_limit_price ,
        order.adjusted_trailing_amount ,
        order.adjustable_trailing_unit ,
        include_ext_operator[  order.ext_operator ] ,
        order.serialize_soft_dollar_tier,
        include_cash_qty[ order.cash_qty ] ,
        order.serialize_mifid_order_fields,
        include_auto_price_for_hedge[ order.dont_use_auto_price_for_hedge ],
        include_order_container[  order.is_O_ms_container ],
        include_d_peg_order[ order.discretionary_up_to_limit_price ],
        include_price_mgmt_algo[ order.use_price_management_algo ],
        include_duration[ order.duration ],
        include_ats[ order.post_to_ats ],
        include_auto_cancel_parent[ order.auto_cancel_parent ],
        include_advanced_reject[ order.advanced_order_reject ],
        include_manual_order_time[ order.manual_order_time ],
        order.serialize_peg_best_and_mid,
        include_customer_account[ order.customer_account  ],
        include_professional_customer[ order.professional_account  ]
         ]
        end  # encode
      end # PlaceOrder


    end # module Outgoing
  end # module Messages
end # module IB
