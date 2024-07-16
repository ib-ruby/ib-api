module IB
  class Contract <  IB::Base
    include BaseProperties

    # Fields are Strings unless noted otherwise
    prop :con_id, # int: The unique contract identifier.
      :currency, # Only needed if there is an ambiguity, e.g. when SMART exchange
      #            and IBM is being requested (IBM can trade in GBP or USD).

      :legs_description, # received in OpenOrder for all combos

      :sec_type, # Security type. Valid values are: SECURITY_TYPES

      :sec_id => :sup, # Unique identifier of the given secIdType.

      :sec_id_type => :sup, # Security identifier, when querying contract details or
      #               when placing orders. Supported identifiers are:
      #               -  ISIN (Example: Apple: US0378331005)
      #               -  CUSIP (Example: Apple: 037833100)
      #               -  SEDOL (6-AN + check digit. Example: BAE: 0263494)
      #               -  RIC (exchange-independent RIC Root and exchange-
      #                  identifying suffix. Ex: AAPL.O for Apple on NASDAQ.)

      :symbol => :s, # This is the symbol of the underlying asset.

      :local_symbol => :s, # Local exchange symbol of the underlying asset
      :trading_class => :s,
      # Future/option contract multiplier (only needed when multiple possibilities exist)
      :multiplier => {:set => :i},

      :strike => :f, # double: The strike price.
      :expiry => :s, # The expiration date. Use the format YYYYMM or YYYYMMDD
      :last_trading_day =>  :s, # the tws returns the last trading day in Format YYYYMMMDD hh:mm
        # which may differ from the expiry 
      :exchange => :sup, # The order destination, such as Smart.
      :primary_exchange => :sup, # Non-SMART exchange where the contract trades.
      :include_expired => :bool, # When true, contract details requests and historical
      #         data queries can be performed pertaining to expired contracts.
      #         Note: Historical data queries on expired contracts are
      #         limited to the last year of the contracts life, and are
      #         only supported for expired futures contracts.
      #         This field can NOT be set to true for orders.


      # Specifies a Put or Call. Valid input values are: P, PUT, C, CALL
    :right => {
      :set => proc { |val|
        self[:right] =
        case val.to_s.upcase
        when 'NONE', '', '0', '?'
          ''
        when 'PUT', 'P'
          'P'
        when 'CALL', 'C'
          'C'
        else
          val
        end
      },
      :validate => {:format => {:with => /\Aput$|^call$|^none\z/,
                                :message => "should be put, call or none"}}
    }

    attr_accessor :description # NB: local to ib, not part of TWS.

    ### Associations
    has_many :misc   # multi purpose association
    has_many :orders # Placed for this Contract
    has_many :portfolio_values

    has_many :bars # Possibly representing trading history for this Contract

    has_one :contract_detail # Volatile info about this Contract

    # For Contracts that are part of BAa ## leg is now a method of contract
#   has_one :leg #, :class_name => 'ComboLeg', :foreign_key => :leg_contract_id
   # has_one :combo, :class_name => 'Contract', :through => :leg

    # for Combo/BAG Contracts that contain ComboLegs
    has_many :combo_legs#, :foreign_key => :combo_id
 #   has_many :leg_contracts, :class_name => 'Contract', :through => :combo_legs
#    alias legs combo_legs
 #   alias legs= combo_legs=

  #    alias combo_legs_description legs_description
  #  alias combo_legs_description= legs_description=

      # for Delta-Neutral Combo Contracts
      has_one :underlying
    alias under_comp underlying
    alias under_comp= underlying=


      ### Extra validations
      validates_inclusion_of :sec_type, :in => CODES[:sec_type].keys,
      :message => "should be valid security type"

    validates_format_of :expiry, :with => /\A\d{6}$|^\d{8}$|\A\z/,
      :message => "should be YYYYMM or YYYYMMDD"

    validates_format_of :primary_exchange, :without => /SMART/,
      :message => "should not be SMART"

    validates_format_of :sec_id_type, :with => /ISIN|SEDOL|CUSIP|RIC|\A\z/,
      :message => "should be valid security identifier"

    validates_numericality_of :multiplier, :strike, :allow_nil => true

    def default_attributes  # :nodoc:
      super.merge :con_id => 0,
        :strike => "",
        :right => :none, # Not an option
       # :exchange => 'SMART',
        :include_expired => false
    end


#    This returns an Array of data from the given contract and is used to represent
#    contracts in outgoing messages.
#
#    Different messages serialize contracts differently. Go figure.
#
#    Note that it does NOT include the combo legs.
#    serialize :option, :con_id, :include_expired, :sec_id
#
#    18/1/18: serialise always includes con_id

    def serialize *fields  # :nodoc:
      print_default = ->(field, default="") { field.blank? ? default : field }
      [(con_id.present? && !con_id.is_a?(Symbol) && con_id.to_i > 0 ? con_id : ""),
       print_default[symbol],
       print_default[self[:sec_type]],
       ( fields.include?(:option) ?
       [ print_default[expiry],
      ##  a Zero-Strike-Option  has to be defined with  «strike: -1 »
         strike.present? && ( strike.is_a?(Numeric) && !strike.zero? && strike > 0 )  ?  strike : strike<0 ?  0 : "",
         print_default[self[:right]],
         print_default[multiplier]] : nil ),
       print_default[exchange],
       ( fields.include?(:primary_exchange) ? print_default[primary_exchange]   : nil ) ,
       print_default[currency],
       print_default[local_symbol],
       ( fields.include?(:trading_class) ? print_default[trading_class] : nil ),
       ( fields.include?(:include_expired) ? print_default[include_expired,0] : nil ),
       ( fields.include?(:sec_id_type) ? [print_default[sec_id_type], print_default[sec_id]] : nil )
       ].flatten.compact
    end

    # serialize contract
    # con_id. sec_type, expiry, strike, right, multiplier exchange, primary_exchange, currency, local_symbol, include_expired
    # other fields on demand
    def serialize_long *fields # :nodoc:
      serialize :option, :include_expired, :primary_exchange, :trading_class, *fields
    end

    # serialize contract
    # con_id. sec_type, expiry, strike, right, multiplier, exchange, primary_exchange, currency, local_symbol
    # other fields on demand
    # acutal used by place_order, request_marketdata, request_market_depth, exercise_options
    def serialize_short *fields  # :nodoc:
      serialize :option, :trading_class, :primary_exchange, *fields
    end

    # same as :serialize_short, omitting primary_exchange
      # used by      RequestMarketDepth
    def serialize_supershort *fields  # :nodoc:
      serialize :option, :trading_class,  *fields
    end

    # Serialize under_comp parameters: EClientSocket.java, line 471
    def serialize_under_comp *args   # :nodoc:
      under_comp ? [true] + under_comp.serialize : [false]
    end

    # Defined in Contract, not BAG subclass to keep code DRY
    def serialize_legs *fields     # :nodoc:
      case
      when !bag?
       []
      when combo_legs.empty?
        [0]
      else
        [combo_legs.size, combo_legs.map { |the_leg| the_leg.serialize *fields }].flatten
      end
    end



    # This produces a string uniquely identifying this contract, in the format used
    # for command line arguments in the IB-Ruby examples. The format is:
    #
    #    symbol:sec_type:expiry:strike:right:multiplier:exchange:primary_exchange:currency:local_symbol
    #
    # Fields not needed for a particular security should be left blank
    # (e.g. strike and right are only relevant for options.)
    #
    # For example, to query the British pound futures contract trading on Globex
    # expiring in September, 2008, the string is:
    #
    #    GBP:FUT:200809:::62500:GLOBEX::USD:
    def serialize_ib_ruby
      serialize_long.join(":")
    end

    # extracts essential attributes of the contract,
    # and returns a new contract. Used for comparism of equality of contracts
    #
    # the link to contract-details is __not__ maintained.
    def  essential

      the_attributes = [ :sec_type, :symbol , :con_id,   :exchange, :right,
                    :currency, :expiry,  :strike,   :local_symbol, :last_trading_day,
                :multiplier,  :primary_exchange, :trading_class, :description ]
      new_contract= self.class.new( invariant_attributes.select{|k,_| the_attributes.include? k }
                                                        .transform_values{|v| v.is_a?(Numeric)? v : v.to_s.upcase } )
      new_contract[:description] = if @description.present?
                                     @description
                                   elsif contract_detail.present?
                                     contract_detail.long_name
                                   else
                                     ""
                                   end
      new_contract # return contract
    end


    # creates a new Contract substituting attributes by the provided key-value pairs.
    #
    # for convenience
    # con_id, local_symbol and last_trading_day are resetted,
    # the link to contract-details is savaged
    #
    # Example
    #   ge =  Stock.new( symbol: :ge).verify.first
    #   f = ge.merge symbol: :f
    #
    #   c =  Contract.new( con_id: 428520002,  exchange: 'Globex')
    #puts c.verify.as_table
#┌────────┬────────┬───────────┬──────────┬──────────┬────────────┬───────────────┬───────┬────────┬──────────┐
#│        │ symbol │ con_id    │ exchange │ expiry   │ multiplier │ trading-class │ right │ strike │ currency │
#╞════════╪════════╪═══════════╪══════════╪══════════╪════════════╪═══════════════╪═══════╪════════╪══════════╡
#│ Future │ NQ     │ 428520002 │  GLOBEX  │ 20210917 │     20     │      NQ       │       │        │   USD    │
#└────────┴────────┴───────────┴──────────┴──────────┴────────────┴───────────────┴───────┴────────┴──────────┘
    # d= c.merge symbol: :es, trading_class: '', multiplier: 50
    # puts d.verify.as_table
#┌────────┬────────┬───────────┬──────────┬──────────┬────────────┬───────────────┬───────┬────────┬──────────┐
#│        │ symbol │ con_id    │ exchange │ expiry   │ multiplier │ trading-class │ right │ strike │ currency │
#╞════════╪════════╪═══════════╪══════════╪══════════╪════════════╪═══════════════╪═══════╪════════╪══════════╡
#│ Future │ ES     │ 428520022 │  GLOBEX  │ 20210917 │     50     │      ES       │       │        │   USD    │
#│ Future │ ES     │ 446091461 │  GLOBEX  │ 20211217 │     50     │      ES       │       │        │   USD    │
#│ Future │ ES     │ 461318816 │  GLOBEX  │ 20220318 │     50     │      ES       │       │        │   USD    │
#│ Future │ ES     │ 477836957 │  GLOBEX  │ 20220617 │     50     │      ES       │       │        │   USD    │
#│ Future │ ES     │ 495512551 │  GLOBEX  │ 20221216 │     50     │      ES       │       │        │   USD    │
#│ Future │ ES     │ 495512552 │  GLOBEX  │ 20231215 │     50     │      ES       │       │        │   USD    │
#│ Future │ ES     │ 495512557 │  GLOBEX  │ 20241220 │     50     │      ES       │       │        │   USD    │
#│ Future │ ES     │ 495512563 │  GLOBEX  │ 20251219 │     50     │      ES       │       │        │   USD    │
#│ Future │ ES     │ 495512566 │  GLOBEX  │ 20220916 │     50     │      ES       │       │        │   USD    │
#│ Future │ ES     │ 495512569 │  GLOBEX  │ 20230616 │     50     │      ES       │       │        │   USD    │
#│ Future │ ES     │ 495512572 │  GLOBEX  │ 20230317 │     50     │      ES       │       │        │   USD    │
#│ Future │ ES     │ 497222760 │  GLOBEX  │ 20230915 │     50     │      ES       │       │        │   USD    │
#└────────┴────────┴───────────┴──────────┴──────────┴────────────┴───────────────┴───────┴────────┴──────────┘

    def merge **new_attributes

      resetted_attributes = [:con_id, :local_symbol, :contract_detail]
      ## last_trading_day / expiry needs special treatment
      resetted_attributes << :last_trading_day if  new_attributes.keys.include? :expiry
      self.class.new attributes.reject{|k,_| resetted_attributes.include? k}.merge(new_attributes)
    end

    # Contract comparison

    def == other  # :nodoc:
#      a = ->(e){ e.essential.invariant_attributes.select{|y,_| ![:description, :include_expired, :con_id, :trading_class, :primary_exchange].include? y} }
      return true if self.con_id == other.con_id
#      a.call(self) == a.call(other)
      common_keys = self.invariant_attributes.keys & other.invariant_attributes.keys
      common_keys.all? do |key|
          value1 = attributes[key]
          value2 = other.attributes[key]
          next true if value1 == value2
          value1.to_i.zero? || value2.to_i.zero? rescue true
      end
    end

#    def to_s
#      "<Contract: " + instance_variables.map do |key|
#        value = send(key[1..-1])
#        " #{key}=#{value} (#{value.class}) " unless value.blank?
#      end.compact.join(',') + " >"
#    end

    def to_human
      "<Contract: " +
        [symbol,
         sec_type,
         (expiry == '' ? nil : expiry),
         (right == :none ? nil : right),
         (strike == 0 ? nil : strike),
         exchange,
         currency
         ].compact.join(" ") + ">"
    end

    alias to_s to_human

    # Testing for type of contract:
    # depreciated :  use is_a?(IB::Stock, IB::Bond, IB::Bag etc) instead
    def bag?  #  :nodoc:
      self[:sec_type] == 'BAG'
    end

    def bond?  #  :nodoc:

      self[:sec_type] == 'BOND'
    end

    def stock? #  :nodoc:

      self[:sec_type] == 'STK'
    end

    def option?  #  :nodoc:

      self[:sec_type] == 'OPT'
    end

    def index?  #  :nodoc:

      self[:sec_type] == 'IND'
    end

    def crypto?  #  :nodoc:

      self[:sec_type] == 'CRYPTO'
    end


=begin
From the release notes of TWS 9.50

Within TWS and Mosaic, we use the last trading day and not the actual expiration date for futures, options and futures options contracts. To be more accurate, all fields and selectors throughout TWS that were labeled Expiry or Expiration have been changed to Last Trading Day. Note that the last trading day and the expiration date may be the same or different dates.

In many places, such as the OptionTrader, Probability Lab and other options/futures tools, this is a simple case of changing the name of a field to Last Trading Day. In other cases the change is wider-reaching. For example, basket files that include derivatives were previously saved using the Expiry header. When you try to import these legacy .csv files, you will now receive a message requiring that you change this column title to LastTradingDayorContractMonth before the import will be accepted. New basket files that include derivatives will use this correct header. Additionally, this new field serves two functions. If you use the format YYYYMMDD, we understand you are identifying the last trading day for a contract. If you use the format YYYYMM, we understand you are identifying the contract month.

In places where these terms are used to indicate a concept, we have left them as Expiry or Expiration. For example in the Option Chain settings where we allow you to "Load the nearest N expiries" we have left the word expiries. Additionally, the Contract Description window will show both the Last Trading Date and the Expiration Date. Also in cases where it's appropriate, we have replaced Expiry or Expiration with Contract Month.

=end


# IB-ruby uses expiry to query Contracts.
#
# The response from the TWS is stored in 'last_trading_day' (Contract) and 'real_expiration_data' (ContractDetails)
#
# However, after querying a contract, 'expiry' ist overwritten by 'last_trading_day'. The original 'expiry'
# is still available through 'attributes[:expiry]'

    def expiry
      if self.last_trading_day.present?
        last_trading_day.gsub(/-/,'')
      else
        @attributes[:expiry]
      end
    end


# is read by Account#PlaceOrder to set requirements for contract-types, as NonGuaranteed for stock-spreads
    def order_requirements
      Hash.new
    end


    def table_header( &b )
      if block_given?
      [ yield(self) , 'symbol',  'con_id', 'exchange', 'expiry','multiplier', 'trading-class' , 'right', 'strike', 'currency' ]
      else
      [ '', 'symbol',  'con_id', 'exchange', 'expiry','multiplier', 'trading-class' , 'right', 'strike', 'currency' ]
      end
    end

    def table_row
      [ self.class.to_s.demodulize, symbol,
        { value: con_id.zero? ? '' : con_id , alignment: :right},
         { value: exchange, alignment: :center},
         expiry,
         { value: multiplier.zero??  "" : multiplier, alignment: :center},
         { value: trading_class, alignment: :center},
         { value: right == :none ? "": right, alignment: :center },
         { value: strike.zero? ? "": strike, alignment: :right},
         { value: currency, alignment: :center} ]

    end
  end # class Contract
end # module IB

