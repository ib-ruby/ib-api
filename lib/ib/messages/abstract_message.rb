module IB
  module Messages

    # This is just a basic generic message from the server.
    #
    # Class variables:
    # @message_id - int: message id.
    # @message_type - Symbol: message type (e.g. :OpenOrderEnd)
    #
    # Instance attributes (at least):
    # @version - int: current version of message format.
    # @data - Hash of actual data read from a stream.
    class AbstractMessage

      # Class methods
      def self.data_map # Map for converting between structured message and raw data
        @data_map ||= []
      end

      def self.version # Per class, minimum message version supported
        @version || 1
      end

      # including server-version as method to every message class
      def server_version
          Connection.current &.server_version || 165
      end
      def self.message_id
        @message_id
      end

      # Returns message type Symbol (e.g. :OpenOrderEnd)
      def self.message_type
        to_s.split(/::/).last.to_sym
      end

      def message_id
        self.class.message_id
      end

      def request_id
        @data[:request_id].presence || nil
      end

      def message_type
        self.class.message_type
      end

      attr_accessor :created_at, :data

      def self.properties?
        @given_arguments
      end


      def to_human
        "<#{self.message_type}:" +
        @data.map do |key, value|
          unless [:version].include?(key)
            " #{key} #{ value.is_a?(Hash) ? value.inspect : value}"
          end
        end.compact.join(',') + " >"
      end

    end # class AbstractMessage

  end # module Messages
end # module IB
