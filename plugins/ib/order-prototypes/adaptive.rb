
module IB
#  module OrderPrototype
    module Adaptive
      extend OrderPrototype
      class << self

      def defaults
        Limit.defaults.merge algo_strategy: "Adaptive",
                            algo_params: { "adaptivePriority" => "Normal" }
      end

      def aliases
        Limit.aliases
      end

      def requirements
        Limit.requirements
      end


      def summary
	<<-HERE
  The Adaptive Algo combines IB’s Smart routing capabilities with user-defined
  priority settings in an effort to achieve further cost efficiency at the
  point of execution. Using the Adaptive algo leads to better execution prices
  on average than for regular limit or market orders.

  Algo Strategy Value: Adaptive

  adaptivePriority: String. The ‘Priority’ selector determines the time taken
  to scan for better execution prices. The ‘Urgent’ setting scans only briefly,
    while the ‘Patient’ scan works more slowly and has a higher chance of
      achieving a better overall fill for your order.  Valid Value/Format:
        Urgent > Normal > Patient
	HERE
      end
      end
    end
end
