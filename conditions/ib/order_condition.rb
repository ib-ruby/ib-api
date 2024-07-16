module IB
  class OrderCondition < IB::Base
    include BaseProperties


    prop :operator,                 # 1 ->  " >= " , 0 -> " <= "   see /lib/ib/constants # 338f
        :conjunction_connection,    # "o" -> or  "a"
        :contract
    def self.verify_contract_if_necessary c
   c.con_id.to_i.zero? ||( c.primary_exchange.blank? && c.exchange.blank?) ? c.verify! : c
    end
    def condition_type
      error "condition_type method is abstract"
    end
    def  default_attributes
       super.merge(  operator: ">=" , conjunction_connection: :and )
    end

    def serialize_contract_by_con_id
      [ contract.con_id , contract.primary_exchange.presence || contract.exchange ]
    end

    def serialize
      [ condition_type,  self[:conjunction_connection] ]
    end
  end



end # module
