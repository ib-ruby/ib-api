module IB
  module Messages
    module Incoming

      extend Messages # def_message macros


      # Receives previously requested FA configuration information from TWS.

      class AccountMessage < AbstractMessage
        def account_value
          @account_value = IB::AccountValue.new @data[:account_value]
        end
        def account_name
          @account_name =  @data[:account]
        end

        def to_human
        "<AccountValue: #{account_name}, #{account_value}"  
        end
      end


      end # module AccountValues
  end # module Messages
end # module IB
