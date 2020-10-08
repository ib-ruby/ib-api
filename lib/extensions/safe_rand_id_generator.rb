module IB
  module SafeRandIdGenerator
    # we use a duration for the base from the current time and bundle it with
    # current millisecond which gives us uniq enough (in selected time frame) Integer
    def self.call(duration = 365 * 24 * 60 * 60)
      ((Time.now.to_f % duration.to_i) * 1_000).to_i
    end
  end
end
