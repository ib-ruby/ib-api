module IB
  class Alert

    def self.alert_388 msg
             # Order size x is smaller than the minimum required size of yy.
      IB::Gateway.logger.error  msg.inspect
  #     error  msg, :order,  nil
    end
    def self.alert_202 msg
      # do anything in a secure mutex-synchronized-environment
      any_order = IB::Gateway.current.account_data do | account |
        order= account.locate_order( local_id: msg.error_id )
        if order.present? && ( order.order_state.status != 'Cancelled' )
          order.order_states.update_or_create( IB::OrderState.new( status: 'Cancelled', 
                                                                  perm_id: order.perm_id, 
                                                                  local_id: order.local_id  ) ,
                                                                  :status )

        end
        order # return_value
      end
      if any_order.compact.empty? 
        IB::Gateway.logger.error{"Alert 202: The deleted order was not registered: local_id #{msg.error_id}"}
      end

    end


    class << self
=begin
IB::Alert#AddOrderstateAlert

The OrderState-Record is used to record the history of the order.
If selected Alert-Messages appear, they are  added to the Order.order_state-Array.
The last Status is available as Order.order_state, all states are accessible by Order.order_states

The TWS-Message-text is stored to the »warning-text«-field.
The Status is always »rejected«. 
If the first OrderState-object of a Order is »rejected«, the order is not placed at all.
Otherwise only the last action is not applied and the order is unchanged.

=end
      def add_orderstate_alert  *codes
        codes.each do |n|
          class_eval <<-EOD
             def self.alert_#{n} msg

                 if msg.error_id.present?
                    IB::Gateway.current.account_data do | account |
                        order= account.locate_order( local_id: msg.error_id )
                        if order.present? && ( order.order_state.status != 'Rejected' )
                          order.order_states.update_or_create(  IB::OrderState.new( status: 'Rejected' ,
                              perm_id: order.perm_id, 
                              warning_text: '#{n}: '+  msg.message,
                              local_id: msg.error_id ), :status )   

                          IB::Gateway.logger.error{  msg.to_human  }
                        end # order present?
                     end  # mutex-environment
                  end # branch
              end # def
          EOD
        end # loop
      end # def
    end
    add_orderstate_alert  103,  # duplicate order
      201,  # deleted object
      105,  # Order being modified does not match original order
      462,  # Cannot change to the new Time in Force:GTD
      329,  # Cannot change to the new order type:STP
      10147 # OrderId 0 that needs to be cancelled is not found.
  end  # class Alert
end #  module IB
