module IB
  module Messages
    module Incoming
      ExecutionData =
        def_message [11, 0], # [8, 9]],
                    # The reqID that was specified previously in the call to reqExecution()
                    %i[request_id int],
                    %i[execution local_id int],
                    %i[contract contract],
                    %i[execution exec_id string], # Weird format
                    %i[execution time datetime],
                    %i[execution account_name string],
                    %i[execution exchange string],
                    %i[execution side string],
                    %i[execution quantity decimal],
                    %i[execution price decimal],
                    %i[execution perm_id int],
                    %i[execution client_id int],
                    %i[execution liquidation int],
                    %i[execution cumulative_quantity int],
                    %i[execution average_price decimal],
                    %i[execution order_ref string],
                    %i[execution ev_rule string],
                    %i[execution ev_multiplier decimal],
                    %i[execution model_code string],
                    %i[execution last_liquidity int]

      class ExecutionData
        def load
          simple_load
        end

        def contract
          @contract = IB::Contract.build @data[:contract]
        end

        def execution
          @execution = IB::Execution.new @data[:execution]
        end

        def to_human
          "<ExecutionData #{request_id}: #{contract.to_human}, #{execution}>"
        end
      end # ExecutionData
    end # module Incoming
  end # module Messages
end # module IB
