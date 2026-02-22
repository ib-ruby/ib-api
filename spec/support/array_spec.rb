require "spec_helper"

#class Array
#  include Support::ArrayFunction
#end

describe  "Support::ArrayFunction" do
  describe "insert an entry" do
    Given( :the_array  ) { [ ] }
    Given( :the_entry ){   { a: 2, c: 2 } }
    When { the_array.save_insert the_entry, :a }
    Then { the_array ==   [ { a: 2, c: 2 }  ] }
  end
  describe "insert another entry" do
    Given( :the_array  ) { [ { a: 1, b: 2 } ] }
    Given( :the_entry ){   { a: 2, c: 2 } }
    When { the_array.save_insert the_entry, :a }
    Then { the_array ==   [ { a: 1, b: 2 }, { a: 2, c: 2 }  ] }
  end
  describe "overwrite the entry" do
    Given( :the_array  ) { [ { a: 1, b: 2 } , { a: 2, c: 2 } ] }
    Given( :the_entry ){   { a: 2, c: 3 } }
    When { the_array.save_insert the_entry, :a }
    Then { the_array ==   [ { a: 1, b: 2 }, { a: 2, c: 3 }  ] }
  end
  describe "keep the entry" do
    Given( :the_array  ) { [ { a: 1, b: 2 } , { a: 2, c: 2 } ] }
    Given( :the_entry ){   { a: 2, c: 3 } }
    When { the_array.save_insert the_entry, :a, false }
    Then { the_array ==   [ { a: 1, b: 2 }, { a: 2, c: 2 }  ] }
  end
end

