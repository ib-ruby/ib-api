# Include the method `to_bool` to some basic classes
#
# Prepare the output of arrays via Terminal::Table
#
# Define the method `count_duplicates` for Arrays
#
module ClassExtensions
  module Array
    module DuplicatesCounter
      def count_duplicates
        self.each_with_object(Hash.new(0)) { |element, counter| counter[element] += 1 }.sort_by{|k,v| -v}.to_h
      end
    end

    module TablePresenter
      def as_table(&b)
        the_table_header = first.table_header(&b)
        the_table_rows = map &:table_row
        Terminal::Table.new headings: the_table_header, rows: the_table_rows , style: { border: :unicode }
      end
    end
  end

  module Time
    # Render datetime in IB format (zero padded "yyyymmdd HH:mm:ss")
    def to_ib
      "#{year}#{sprintf("%02d", month)}#{sprintf("%02d", day)} " +
        "#{sprintf("%02d", hour)}:#{sprintf("%02d", min)}:#{sprintf("%02d", sec)}"
    end
  end

  module Numeric
    # Conversion 0/1 into true/false
    module Bool
      def to_bool
        self == 0 ? false : true
      end
    end
  end

  module BoolClass
    # Conversion 0/1 into true/false
    module Bool
      def to_bool
        self
      end
    end
  end
  module String
    module Bool
      def to_bool
        case self.chomp.upcase
        when 'TRUE', 'T', '1'
          true
        when 'FALSE', 'F', '0', ''
          false
        else
          error "Unable to convert #{self} to bool"
        end
      end
    end
  end
  module Symbol
    module Float
      def to_f
        0
      end
    end
    module Sort
      # ActiveModel serialization depends on this method
      def <=> other
        to_s <=> other.to_s
      end
    end
  end
    module Object
      # We still need to pass on nil, meaning: no value
      def to_sup
        self.to_s.upcase unless self.nil?
      end
    end

end

Array.include ClassExtensions::Array::DuplicatesCounter
Array.include ClassExtensions::Array::TablePresenter
FalseClass.include ClassExtensions::BoolClass::Bool
NilClass.include ClassExtensions::BoolClass::Bool
Numeric.include ClassExtensions::Numeric::Bool
Object.include ClassExtensions::Object
String.include ClassExtensions::String::Bool
Symbol.include ClassExtensions::Symbol::Float
Symbol.include ClassExtensions::Symbol::Sort
Time.include  ClassExtensions::Time
TrueClass.include ClassExtensions::BoolClass::Bool








### Patching Object#error in ib/errors
#  def error message, type=:standard

### Patching Object#log, #default_logger= in ib/logger
#  def default_logger
#  def default_logger= logger
#  def log *args
