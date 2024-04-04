require "spec_helper"

describe  IB::Connection do
  Given( :ib  ) { IB::Connection.new connect: false }
  Then { ib.is_a? IB::Connection }

  # Check if all Messages are defined
  # There are  51 Incoming Message classes
  Given( :in_classes ){ IB::Messages::Incoming::Classes }
  Then{  in_classes.is_a? Hash }
  Then{  in_classes.size == 51 }

  Given( :out_classes ){ IB::Messages::Outgoing::Classes }
  Then{  out_classes.is_a? Hash }
  Then{  out_classes.size == 53 }
end
