module IB
  # includes methods from IB:.Support
  # which adds a tws-method to
  # - Array
  # - Symbol
  # - String
  # - Numeric
  # - TrueClass, FalseClass and NilClass
  #
  module PrepareData
    using IB::Support
    # First call the method #tws on the data-object
    #
    # Then transfom into an Array using the #Pack-Method
    #
    # The optional Block introduces a user-defined pattern to pack the data.
    #
    # Default is "Na*"
    def prepare_message data
      data =  data.tws unless data.is_a?(String) && data[-1]== EOL
      matrize = [data.size,data]
      if block_given?     # A user defined decoding-sequence is accepted via block
        matrize.pack yield
      else
        matrize.pack  "Na*"
      end
    end

    # The received package is decoded. The parameter (msg) is an Array
    #
    # The protocol is simple: Every Element is treated as Character.
    # Exception: The first Element determines the expected length.
    #
    # The decoded raw-message can further modified by the optional block.
    #
    # The default is to instantiate a Hash: message_id becomes the key.
    # The Hash is returned
      #
      # If a block is provided, no Hash is build and the modified raw-message is returned
      def decode_message msg
        m = Hash.new
        while  not msg.blank?
          # the first item is the length
          size= msg[0..4].unpack("N").first
          msg =  msg[4..-1]
          # followed by a sequence of characters
          message =  msg.unpack("A#{size}").first.split("\0")
          # DEBUG display raw decoded message on STDOUT
#          STDOUT::puts "message: #{message}"
        if block_given?
          yield message
        else
          m[message.shift.to_i] = message
        end
        msg =  msg[size..-1]
      end
      return m unless m == {}
    end

  end
end
