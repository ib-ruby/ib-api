module IB
  module Messages
    module Incoming

        HistogramData  = def_message( [89,0],
                                  [:request_id, :int],
                                  [ :number_of_points , :int ]) do
                                    # to human
          "<HistogramData: #{request_id}, #{number_of_points} read>"
                                  end

      class HistogramData
        attr_accessor :results
        using IB::Support  # extended Array-Class  from abstract_message

        def load
          super

          @results = Array.new(@data[:number_of_points]) do |_|
            { price:  buffer.read_decimal,
             count: buffer.read_int }
          end
        end
      end



    end # module Incoming
  end # module Messages
end # module IB
