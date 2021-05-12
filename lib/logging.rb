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
          @logger = Logger.new(STDOUT)
					@logger.level = Logger::INFO
					@logger.formatter = proc do |severity, datetime, progname, msg|
					#	"#{datetime.strftime("%d.%m.(%X)")}#{"%5s" % severity}->#{msg}\n"
						"#{"%5s" % severity}::#{msg}\n"
					end
				end # branch
        @logger.info "------------------------------ start logging ----------------------------"
			end # def
		end # module ClassMethods
	end # module Logging
end # module Support

