module IB
  module Messages
    module Incoming
      module ContractAccessors
      end

      ContractDetails = ContractData =
        def_message([10, [6, 8]],
                    %i[request_id int], # request id
                    %i[contract symbol string],	## next the major contract-fields
                    %i[contract sec_type string],	## are transmitted
                    %i[contract last_trading_day date],	## difference to the array.get_contract
                    %i[contract strike decimal],	## method: con_id is transmitted
                    %i[contract right string],	## AFTER the main fields
                    %i[contract exchange string],							##
                    %i[contract currency string],							## thus we have to read the fields separately
                    %i[contract local_symbol string],
                    %i[contract_detail market_name string], # extended
                    %i[contract trading_class string], # new Version 8
                    %i[contract con_id int],
                    %i[contract_detail min_tick decimal],
                    %i[contract_detail md_size_multiplier int],
                    %i[contract multiplier int],
                    %i[contract_detail order_types string],
                    %i[contract_detail valid_exchanges string],
                    %i[contract_detail price_magnifier int],
                    %i[contract_detail under_con_id int],
                    %i[contract_detail long_name string],
                    %i[contract primary_exchange string],
                    %i[contract_detail contract_month string],
                    %i[contract_detail industry string],
                    %i[contract_detail category string],
                    %i[contract_detail subcategory string],
                    %i[contract_detail time_zone string],
                    %i[contract_detail trading_hours string],
                    %i[contract_detail liquid_hours string],
                    %i[contract_detail ev_rule decimal],
                    %i[contract_detail ev_multipler string],
                    %i[contract_detail sec_id_list hash],
                    %i[contract_detail agg_group int],
                    %i[contract_detail under_symbol string],
                    %i[contract_detail under_sec_type string],
                    %i[contract_detail market_rule_ids string],
                    %i[contract_detail real_expiration_date date])
      class ContractData
        using IBSupport # defines tws-method for Array  (socket.rb)
        def contract
          @contract = IB::Contract.build @data[:contract].merge(contract_detail: contract_detail)
        end

        def contract_detail
          @contract_detail = IB::ContractDetail.new @data[:contract_detail]
        end

        alias contract_details contract_detail

        def to_human
          "<Contract #{contract.to_human}   #{contract_detail.to_human}>"
        end
      end # ContractData

      BondContractData =
        def_message [18, [4, 6]], ContractData,
                    %i[request_id int],
                    %i[contract symbol string],
                    %i[contract sec_type string],
                    %i[contract_detail cusip string],
                    %i[contract_detail coupon decimal],
                    %i[contract_detail maturity string],
                    %i[contract_detail issue_date string],
                    %i[contract_detail ratings string],
                    %i[contract_detail bond_type string],
                    %i[contract_detail coupon_type string],
                    %i[contract_detail convertible boolean],
                    %i[contract_detail callable boolean],
                    %i[contract_detail puttable boolean],
                    %i[contract_detail desc_append string],
                    %i[contract exchange string],
                    %i[contract currency string],
                    %i[contract_detail market_name string], # extended
                    %i[contract_detail trading_class string],
                    %i[contract con_id int],
                    %i[contract_detail min_tick decimal],
                    %i[contract_detail order_types string],
                    %i[contract_detail valid_exchanges string],
                    %i[contract_detail valid_next_option_date string],
                    %i[contract_detail valid_next_option_type string],
                    %i[contract_detail valid_next_option_partial string],
                    %i[contract_detail notes string],
                    %i[contract_detail long_name string],
                    %i[contract_detail ev_rule decimal],
                    %i[contract_detail ev_multipler string],
                    %i[sec_id_list_count int]
    end # module Incoming
  end # module Messages
end # module IB
