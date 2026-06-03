module IB

=begin
Plugin for advanced Connections

Public API
==========

Extends IB::Connection

Provides
 * IB::Connection.current.check_connection
 * IB::Connection.current.safe_connect
 * IB::Connection.reconect


=end

  module ConnectionTools
    # Handy method to ensure that a connection is established and active.
    #
    # The connection is reset on the IB-side at least once a day. Then the
    # IB-Ruby-Connection has to be reestablished, too.
    #
    # check_connection reconnects if necessary and returns false if the connection is lost.
    #
    # Individial subscriptions have to be placed **after** checking the connection!
    #
    # It delays the process by 6 ms (500 MBit Cable connection, loc. Europe)
    #
    #  a =  Time.now; IB::Connection.current.check_connection; b= Time.now ;b-a
    #   => 0.00066005
    #
    def check_connection
      q =  Queue.new
      count = 0
      result = nil
      z= subscribe( :CurrentTime ) { q.push true }
      loop do
        begin
          send_message(:RequestCurrentTime)                       # 10 ms  ##
          th = Thread.new{ sleep 0.1 ; q.push nil }
          result =  q.pop
          count+=1
          break if result || count > 10
        rescue IOError, Errno::ECONNREFUSED   # connection lost
          count +=1
          retry
        rescue IB::Error # not connected
          logger.info{"not connected ... trying to reconnect "}
          reconnect
          z= subscribe( :CurrentTime ) { q.push true }
          count = 0
          retry
        rescue Workflow::NoTransitionAllowed
          logger.warn{ "Reconnect is not possible, actual state: #{workflow_state} cannot be reached after disconnection"}
          raise
        end
      end
      unsubscribe z
      result #  return value
    end
  end

  class Connection
    include ConnectionTools

    # Self-contained connection logic (based on the original base method)
    # without internal retry — the plugin's try_connection is the sole retry mechanism.
    def _do_try_connection
      logger.progname='IB::Connection#Event:TryConnection'
      if connected?
        error  "Already connected!"
        return
      end
      # TWS always sends NextValidId message at connect - subscribe saves this id
      subscribe(:NextValidId) do |msg|
        logger.progname = "Connection"
        @next_local_id = msg.local_id
        logger.info { "Got next valid order id: #{@next_local_id}." }
      end

      self.socket = IB::Socket.open(@host, @port)
      socket.initialising_handshake
      @parser =  RawMessageParser.new socket
      @parser.each do | the_message |
        @server_version =  the_message.shift.to_i.freeze
        error "ServerVersion does not match  #{@server_version} <--> #{MAX_CLIENT_VER}" if @server_version != MAX_CLIENT_VER

        @remote_connect_time = DateTime.parse the_message.shift.freeze
        @local_connect_time = Time.now.freeze
        @connected = true
        break  #  only receive one message
      end

      # V100 initial handshake
      # Parameters borrowed from the python client
      socket.send_messages 71, 2, @client_id, @optional_capacities
      logger.fatal{ "Connected to server, version: #{@server_version}, " +
                 "using client-id: #{client_id},\n   connection time: " +
                 "#{@local_connect_time} local, " +
                 "#{@remote_connect_time} remote." }
      start_reader
    rescue IB::TransmissionError => e
      logger.fatal "Transmission Error: Retrying establishing the connection"
      logger.fatal  e.msg
      disconnect!
      try_connection!
    end

    # Enhanced try_connection with built-in retry logic.
    # This method OVERRIDES the base Connection#try_connection.
    # It is the sole retry mechanism — _do_try_connection has no internal retry.
    #
    # Up to 100 attempts: first 50 retries every 10 seconds, then every 60 seconds.
    # Subscriptions must be placed after this call returns.
    #
    protected
    def try_connection maximal_count_of_retry=100
      i = -1
      begin
        _do_try_connection
      rescue Errno::ECONNREFUSED => e
        i += 1
        if i < maximal_count_of_retry
          if i.zero?
            logger.info 'No TWS!'
          else
            logger.info { "No TWS        Retry #{i}/ #{maximal_count_of_retry} " }
          end
          sleep i < 50 ? 10 : 60
          retry
        else
          logger.info { "Giving up!!" }
          return false
        end
      rescue Errno::EHOSTUNREACH => e
        error "Cannot connect to specified host  #{e}", :reader, true
        return false
      rescue SocketError => e
        error 'Wrong Adress, connection not possible', :reader, true
        return false
      rescue IB::Error => e
        logger.info e
      end
      self
    end

    def submit_to_alert_1102
      current.subscribe( :Alert ) do
        if [2102, 1101].include? msg.id.to_i # Connectivity between IB and Trader Workstation
                                 #has been restored - data maintained.
          current.disconnect!
          sleep 0.1
          current.check_connection
        end
      end
    end
  end

end
