# These Alerts are always active
module IB
  class Alert

    def self.alert_2102 msg
      # Connectivity between IB and Trader Workstation has been restored - data maintained.
      sleep 0.1  #  no need to wait too long.
      if IB::Gateway.current.check_connection
        IB::Gateway.logger.debug { "Alert 2102: Connection stable" }
      else
        IB::Gateway.current.reconnect
      end
    end
    end
end
