module IB
  module Messages
    module Incoming


      ManagedAccounts =
          def_message 15, [:accounts_list, :string]

      class ManagedAccounts
        def accounts
          accounts_list.split(',').map{|a| Account.new account: a}
        end

        def to_human
          "<ManagedAccounts: #{accounts.map(&:account).join(" - ")}>"
        end
      end

    end # module Incoming
  end # module Messages
end # module IB
