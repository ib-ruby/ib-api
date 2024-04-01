require "spec_helper"

# Test if tweeking of basic classes works as expected

RSpec.describe ClassExtensions do

  context "Array-Extensions" do

  end
	context "Time-Extensions" do
    Given( :the_time ){ Time.now }
    Then{ the_time.to_ib == the_time.strftime("%Y%m%d %H:%M:%S") }
	end

  # Numeric positive Values are true, zero and below is false
  context "numeric boolean Test" do
    Given( :the_var ){  45 }
    Then{ the_var.is_a? Numeric }
    Then{ the_var.to_bool }
    Given( :the_zero_var ){  0 }
    Then{ !the_zero_var.to_bool }
    Given( :the_negative_var ){  -54 }
    Then{ !the_zero_var.to_bool }
  end

  context "string boolean Tests" do 
    Given( :the_var ){ "false" }
    Then{ !the_var.to_bool }
    Given( :the_f_var ){ "f" }
    Then{ !the_var.to_bool }
    Given( :the_true_var ){ "true" }
    Then{ the_true_var.to_bool }
    Given( :the_t_var ){ "t" }
    Then{ the_true_var.to_bool }
    Given( :the_1_var ){ "1" }
    Then{ the_1_var.to_bool }
    Given( :the_0_var ){ "0" }
    Then{ !the_0_var.to_bool }
    Given( :the_empty_var ){ "" }
    Then{ !the_empty_var.to_bool }
    Given( :the_nonempty_var ){ "not empty" }
    Then{ expect{ the_nonempty_var.to_bool }.to raise_error( IB::Error )  }
  end

  context "native boolean Tests" do 
    Given( :the_var  ){ true }
    Then{ the_var.to_bool  }

    Given( :the_false_var ){ false }
    Then{ !the_false_var.to_bool }

    Given( :the_nil_var ){ nil }
    Then{ !the_nil_var.to_bool }
  end

end
