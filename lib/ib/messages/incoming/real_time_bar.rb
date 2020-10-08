module IB
  module Messages
    module Incoming
      # RealTimeBar contains following @data:
      #    :request_id - The ID of the *request* to which this is responding
      #    :time - The date-time stamp of the start of the bar. The format is offset in
      #            seconds from the beginning of 1970, same format as the UNIX epoch time
      #    :bar - received RT Bar
      RealTimeBar = def_message [50, 3],
                                %i[request_id int],
                                %i[bar time int_date],
                                %i[bar open decimal],
                                %i[bar high decimal],
                                %i[bar low decimal],
                                %i[bar close decimal],
                                %i[bar volume int],
                                %i[bar wap decimal],
                                %i[bar trades int]
      class RealTimeBar
        def bar
          @bar = IB::Bar.new @data[:bar]
        end

        def to_human
          "<RealTimeBar: #{request_id} #{bar}>"
        end
      end # RealTimeBar
    end # module Incoming
  end # module Messages
end # module IB
