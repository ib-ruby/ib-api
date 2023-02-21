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

			def configure_logger(log= STDOUT)
        if log.is_a? Logger
					@logger = log
				else
					@logger = Logger.new log
        end
        @logger.level = Logger::INFO
        @logger.formatter = proc do |severity, datetime, progname, msg|
					#	"#{datetime.strftime("%d.%m.(%X)")}#{"%5s" % severity}->#{msg}\n"
						"#{"%1s" % severity[0]}: #{msg}\n"
					end
        @logger.debug "------------------------------ start logging ----------------------------"
			end # def
		end # module ClassMethods
	end # module Logging
end # module Support

# source: https://github.com/jondot/sneakers/blob/master/lib/sneakers/concerns/logging.rb
