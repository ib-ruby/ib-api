module IB

  # Here we reopen IB::Contract and implenent the dynamic build facility
  # This file is required after zeitwerk processed the basic includes.
  #
  class Contract
    # Contract subclasses representing specialized security types.
    using IB::Support

    Subclasses = Hash.new(Contract)
    Subclasses[:bag] = IB::Bag
    Subclasses[:option] = IB::Option
    Subclasses[:futures_option] = IB::FutureOption
    Subclasses[:future] = IB::Future
    Subclasses[:stock] = IB::Stock
    Subclasses[:forex] =  IB::Forex
    Subclasses[:index] = IB::Index


    # This builds an appropriate Contract subclass based on its type
    #
    # the method is also used to copy Contract.values to new instances
    def self.build opts = {}
      subclass =( VALUES[:sec_type][opts[:sec_type]] || opts['sec_type'] || opts[:sec_type]).to_sym
      Contract::Subclasses[subclass].new opts
    end


  end # class Contract
end
