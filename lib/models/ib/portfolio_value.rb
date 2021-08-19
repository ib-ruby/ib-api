module IB
class PortfolioValue < IB::Model
    include BaseProperties
#	belongs_to :currency
	belongs_to :account
	belongs_to :contract

#	scope :single, ->(key) { where :schluessel => key } rescue nil

    prop :position, 
	:market_price, 
	:market_value, 
	:average_cost, 
	:unrealized_pnl, 
	:realized_pnl


    # Order comparison
    def == other
      super(other) ||
        other.is_a?(self.class) &&
        market_price == other.market_price &&
        average_cost == other.average_cost &&
        position == other.position &&
	unrealized_pnl == other.unrealized_pnl  &&
	realized_pnl == other.realized_pnl &&
        contract == other.contract
    end
    def to_human
			the_account = if account.present? 
											if account.is_a?(String)
												account + " "
											else
												account.account+" "
											end
										else 
											""
										end

			"<PortfolioValue: "+
		  the_account  +
      "Pos=#{ position.to_i } @ #{market_price.to_f.round(3)};" +
      "Value=#{market_value.to_f.round(2)};PNL=" + 
			( unrealized_pnl.to_i.zero? ? "": "#{unrealized_pnl} unrealized;") +
      ( realized_pnl.to_i.zero? ? "" : "#{realized_pnl} realized;>" ) + 
			contract.to_human
    end
    alias to_s to_human

    def table_header
      if block_given?
      [ '' ,   yield , 'pos',  'entry', 'market', 'value', 'unrealized', 'realized'  ]
      else
      [ '' ,   '', 'pos',  'entry', 'market', 'value', 'unrealized', 'realized'  ]
      end
    end

    def table_row
      outprice= ->( item ) { { value: item.nil? ? "--" :  item , alignment: :right } } 

			the_account = if account.present? 
											if account.is_a?(String)
												account + " "
											else
												account.account+" "
											end
										else 
											""
										end
      
      entry = average_cost.to_f / (contract.multiplier.to_i.zero? ?  1 : contract.multiplier.to_i)

      [ the_account,
        contract.to_human[1..-2],
       outprice[position.to_i],
       outprice[entry.to_f.round(3)],
       outprice[market_price.to_f.round(3)],
       outprice[market_value.to_f.round(2)],
			 unrealized_pnl.to_i.zero? ? "": outprice[unrealized_pnl], 
       realized_pnl.to_i.zero? ? "" : outprice[realized_pnl] 
      ]
    end


end # class
end # module
