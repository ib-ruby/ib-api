
module IB
  module Messages
    module Incoming

      extend Messages # def_message macros


      # Receives previously requested FA configuration information from TWS.
      ReceiveFA =
          def_message 16, [:type, :int], # type of Financial Advisor configuration data
                      #                    being received from TWS. Valid values include:
                      #                    1 = GROUPS, 2 = PROFILE, 3 = ACCOUNT ALIASES
                      [:xml, :xml] # XML string with requested FA configuration information.

				class ReceiveFA
					def accounts
						if( a= xml[:ListOfAccountAliases][:AccountAlias]).is_a? Array
							a.map{|x| Account.new x }
						elsif a.is_a? Hash			## only one account (soley financial advisor)
							[ Account.new( a ) ]
						end
					end

					def to_human
						"<FA: #{accounts.map(&:to_human).join(" - ")}>"
					end
				end
		end
  end
end
