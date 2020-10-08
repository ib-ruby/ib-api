module IB
  module Messages
    module Incoming
      # Called Error in Java code, but in fact this type of messages also
      # deliver system alerts and additional (non-error) info from TWS.
      ErrorMessage = Error = Alert = def_message([4, 2],
                                                 %i[error_id int],
                                                 %i[code int],
                                                 %i[message string])
      class Alert
        # Is it an Error message?
        def error?
          code < 1000
        end

        # Is it a System message?
        def system?
          code > 1000 && code < 2000
        end

        # Is it a Warning message?
        def warning?
          code > 2000
        end

        def to_human
          "TWS #{if error?
                   'Error'
                 else
                   system? ? 'System' : 'Warning'
                 end} #{code}: #{message}"
        end
      end # class Alert
    end # module Incoming
  end # module Messages
end # module IB
