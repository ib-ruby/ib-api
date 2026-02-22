module IB
  class Alert
=begin
The Singleton IB::Alert handles any response to IB:Messages::Incomming:Alert

Individual methods can be defined as well as methods responding to a group of error-codes.
The default-behavior is defined in the method_missing-method. This just logs the object at the debug level.

Default-wrappers to completely ignore the error-message (ignore_alert)
and to log the object in a different log-level (log_alert_in [warn,info,error] ) are defined in base_alert.

Just add
```
  module IB
    class Alert
      log_alert_in_warn {list of codennumbers}
    end
  end
```
to your code


IB::Gateway calls the methods in response of subscribing to the :Alert signal by calling
   IB::Alert.send("alert_#{msg.code}", msg )

To define a response to the code 134 ( Modify order failed)  a method like
    module IB
      class Alert
        def self.alert_134 msg
          (your code)
        end
      end
    end
has to be written.

Important: The class is accessed asynchronically. Be careful while raising interrupts.

=end

    # acts as prototype for any generated method
    #require 'active_support'


    def self.method_missing( method_id, msg , *args, &block )
      if msg.is_a?  IB::Messages::Incoming::Alert
#       IB::Connection.logger.debug { msg.to_human }
      else
        IB::Connection.logger.error { "Argument to IB::Alert is not a IB::Messages::Incoming::Alert" }
        IB::Connection.logger.error { "The object: #{msg.inspect} " }
      end
    rescue NoMethodError
      unless IB::Connection.logger.nil?
        IB::Connection.logger.error { "The Argument is not a valid  IB::Messages:Incoming::Alert object"}
        IB::Connection.logger.error { "The object: #{msg.inspect} " }
      else
        puts "No Logging-Device specified"
        puts "The object: #{msg.inspect} "
      end
    end



    class << self

      def ignore_alert  *codes
        codes.each do |n|
          class_eval <<-EOD
        def self.alert_#{n} msg
          # even the log_debug entry is suppressed 
        end              
          EOD
        end
      end
      def log_alert_in_info  *codes
        codes.each do |n|
          class_eval <<-EOD
        def self.alert_#{n} msg
          #       IB::Connection.logger.info { msg.to_human }
        end              
          EOD
        end
      end
      def log_alert_in_warn  *codes
        codes.each do |n|
          class_eval <<-EOD
        def self.alert_#{n} msg
          #       IB::Connection.logger.warn { msg.to_human }
        end              
          EOD
        end
      end

      def log_alert_in_error  *codes
        codes.each do |n|
          class_eval <<-EOD
        def self.alert_#{n} msg
          if msg.error_id.present? && msg.error_id > 0
          #     IB::Connection.logger.error {  msg.message + ' id: ' + msg.error_id.to_s }
          else
          #     IB::Connection.logger.error {  msg.message   }
          end
        end              
            EOD
        end
      end
    end

      ignore_alert 200 , # is handled by IB::Contract.update_contract
        2100, # API client has been unsubscribed from account data
        2105,
        399 # your order will not be placed at the exchange until

      log_alert_in_info    1102 #Connectivity between IB and Trader Workstation has been restored


      log_alert_in_error 320, 321, 323, 324, #ServerError
        ##        110, # The price does not conform to the minimum price variation
        #       103, #duplicate order  ## order-alerts
        #       201, #deleted objecta  ## order-alerts
        326 #Unable connect as the client id is already in use

      log_alert_in_warn  354 #Requested market data is not subscribed

    end
  end
