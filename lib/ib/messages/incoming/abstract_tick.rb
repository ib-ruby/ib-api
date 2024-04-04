
module IB
  module Messages
    module Incoming
      extend Messages # def_message macros
      class AbstractTick < AbstractMessage
        # Returns Symbol with a meaningful name for received tick type
        def type
          TICK_TYPES[@data[:tick_type]]
        end

        def to_human
          "<#{self.message_type} #{type}:" +
              @data.map do |key, value|
                " #{key} #{value}" unless [:version, :ticker_id, :tick_type].include?(key)
              end.compact.join('",') + " >"
        end

				def the_data
					@data.reject{|k,_| [:version, :ticker_id].include? k }
				end
			end
    end
  end
end
