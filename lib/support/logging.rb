#module Kernel
#  private
#  def this_method_name
#    caller[0] =~ /`([^']*)'/  and $1
#  end
#   see also __method__  and __callee__
#end



module Support
  module Logging
    def self.included(base)
      base.extend ClassMethods
      base.send :define_method, :logger do
        base.logger
      end
    end

    module ClassMethods
      def logger
        @logger
      end

      def logger=(logger)
        @logger = logger
      end

      def configure_logger(log=nil)
        if log
          @logger = log
        else
          @logger = ::Logger.new(STDOUT)
          @logger.level = ::Logger::INFO
          @logger.formatter = proc do |severity, datetime, progname, msg|
          # "#{datetime.strftime("%d.%m.(%X)")}#{"%5s" % severity}->#{msg}\n"
            "#{"%1s" % severity[0]}: #{msg}\n"
          end
            @logger.debug "------------------------------ start logging ----------------------------"
        end # branch
      end # def
    end # module ClassMethods
  end # module Logging
end # module Support

