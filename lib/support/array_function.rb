module Support
  module ArrayFunction
    def save_insert item, key, overwrite = true
      member = find { |entry| entry[ key ] == item[ key]  }
      if member
        self[ index( member ) ] = item if overwrite
      else
        self << item
      end
      self  # always returns the array
    end

    # performs [ [ array ] & [ array ] & [..] ].first
    def intercept
      a = self.dup
      s = a.pop
      while a.present?
        s = s & a.pop
      end
      s.first unless s.nil?  # return_value (or nil)
    end
  end  # module
end  # module

class Array
  include Support::ArrayFunction
end

