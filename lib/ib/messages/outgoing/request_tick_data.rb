
module IB
  module Messages
    module Outgoing
      extend Messages # def_message macros



      RequestTickByTickData = 
											def_message [0, 97], :request_id,			# autogenerated if not specified
                      [:contract, :serialize_short, :primary_exchange],  # include primary exchange in request
											:tick_type,  # a string  supported: "Last", "AllLast", "BidAsk" or "MidPoint".
											# Server_version >= 140
											 :number_of_ticks,  # int
										 :ignore_size      # bool

      CancelTickByTickData =
          def_message [0, 98], :request_id
    end
  end
end
