# frozen_string_literal: true

module IB
  # Convert data passed in from a TCP socket stream, and convert into
  # raw messages. The messages
  class RawMessageParser
    HEADER_LNGTH = 4
    def initialize(socket)
      @socket = socket
      @data = String.new
    end

    def each
      while true
        append_new_data
        # puts "looping: #{@data.inspect}"
       
        # Do we have the length message?
        next unless length_data?

        # Based on the length, do we have 
        # enough data to process a full 
        # message?
        next unless enough_data?

        length = next_msg_length
        validate_data_header(length)

        raw = grab_message(length)
        validate_message_footer(raw, length)
        msg = parse_message(raw, length)
        remove_message
        yield msg
      end
    end

    # extract message and convert to
    # an array split by null characters.
    def grab_message(length)
      @data.byteslice(HEADER_LNGTH, length)
    end

    def parse_message(raw, length)
      raw.unpack1("A#{length}").split("\0")
    end

    def remove_message
      length = next_msg_length
      leftovers = @data.byteslice(length + HEADER_LNGTH..-1)
      @data = if leftovers.nil?
                String.new
              else
                leftovers
              end
    end

    def enough_data?
      actual_lngth = next_msg_length + HEADER_LNGTH
      echo 'too little data' if next_msg_length.nil?
      return false if next_msg_length.nil?

      @data.bytesize >= actual_lngth
    end

    def length_data?
      @data.bytesize > HEADER_LNGTH
    end

    def next_msg_length
      # can't check length if first 4 bytes don't exist
      length = @data.byteslice(0..3).unpack1('N')
      return 0 if length.nil?

      length
    end

    def append_new_data
      @data += @socket.recvfrom(4096)[0]
    end

    def validate_message_footer(msg, _length)
      last = msg.bytesize
      last_byte = msg.byteslice(last - 1, last)
      raise 'Could not validate last byte' if last_byte.nil?
      raise "Message has an invalid last byte. expecting \0, received: #{last_byte}" if last_byte != "\0"
    end

    def validate_data_header(length)
      return true if length <= 5000

      raise 'Message is longer than sane max length'
    end
  end
end
