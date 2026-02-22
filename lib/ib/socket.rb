module IB
  # includes methods from IB:.Support
  # which adds a tws-method to
  # - Array
  # - Symbol
  # - String
  # - Numeric
  # - TrueClass, FalseClass and NilClass
  #
  class Socket < TCPSocket
    include IB::PrepareData
    using IB::Support

    def initialising_handshake
      v100_prefix = "API".tws.encode 'ascii'
      v100_version = self.prepare_message Messages::SERVER_VERSION
      write_data v100_prefix+v100_version
      ## start tws-log
      # [QO] INFO  [JTS-SocketListener-49] - State: HEADER, IsAPI: UNKNOWN
      # [QO] INFO  [JTS-SocketListener-49] - State: STOP, IsAPI: YES
      # [QO] INFO  [JTS-SocketListener-49] - ArEServer: Adding 392382055 with id 2147483647
      # [QO] INFO  [JTS-SocketListener-49] - eServersChanged: 1
      # [QO] INFO  [JTS-EServerSocket-287] - [2147483647:136:136:1:0:0:0:SYS] Starting new conversation with client on 127.0.0.1
      # [QO] INFO  [JTS-EServerSocketNotifier-288] - Starting async queue thread
      # [QO] INFO  [JTS-EServerSocket-287] - [2147483647:136:136:1:0:0:0:SYS] Server version is 136
      # [QO] INFO  [JTS-EServerSocket-287] - [2147483647:136:136:1:0:0:0:SYS] Client version is 136
      # [QO] INFO  [JTS-EServerSocket-287] - [2147483647:136:136:1:0:0:0:SYS] is 3rdParty true
      ## end tws-log
    end


    def read_string
      string = self.gets(EOL)

      until string
        # Silently ignores nils
        string = self.gets(EOL)
        sleep 0.1
      end

      string.chomp
    end


    # Sends null terminated data string into socket
    def write_data data
      self.syswrite data.tws
    end

    # send the message (containing several instructions) to the socket,
    # calls prepare_message to convert data-elements into NULL-terminated strings
    def send_messages *data
      self.syswrite prepare_message(data)
    rescue Errno::ECONNRESET =>  e
      Connection.logger.fatal{ "Data not accepted by IB \n
        #{data.inspect} \n
        Backtrace:\n "}
      Connection.logger.error   e.backtrace
    end

    def receive_messages
      begin
        complete_message_buffer = []
        begin
          # this is the blocking version of recv
          buffer =  self.recvfrom(8192)[0]
          #          STDOUT.puts "BUFFER:: #{buffer.inspect}"
          complete_message_buffer << buffer

        end while buffer.size == 8192
        complete_message_buffer.join('')
      rescue Errno::ECONNRESET =>  e
        Connection.logger.fatal{ "Data Buffer is not filling \n
        The Buffer: #{buffer.inspect} \n
        Backtrace:\n 
        #{e.backtrace.join("\n") } " }
        Kernel.exit
      end
    end

  end # class Socket

end # module IB
