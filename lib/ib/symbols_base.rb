
module IB
#  module SymbolExtention  # method_missing may not be refined
#    refine Array do
#      def method_missing(method, *key)
#	unless method == :to_hash || method == :to_str #|| method == :to_int
#	  return self.map{|x| x.public_send(method, *key)}
#	end
#      end
#    end
#  end 

  module Symbols
#    using SymbolExtention


		def hardcoded?
			!self.methods.include? :yml_file
		end
		def method_missing(method, *key)
			if key.empty? 
				if contracts.has_key?(method)
					contracts[method]
					elsif methods.include?(:each) && each.methods.include?(method)
							self.each.send method  				
					else
					error "contract #{method} not defined. Try »all« for a list of defined Contracts.", :symbol
				end
			else
				error "method missing"
			end
		end

		def all
			contracts.keys.sort rescue contracts.keys
		end
		def print_all
			puts contracts.sort.map{|x,y| [x,y.description].join(" -> ")}.join "\n"
		end
		def contracts
			if @contracts.present?
				@contracts
			else
				@contracts = Hash.new
			end
		end
		def [] symbol
			if c=contracts[symbol]
				return c
			else
				# symbol probably has not been predefined, tell user about it
				file = self.to_s.split(/::/).last.downcase
				msg = "Unknown symbol :#{symbol}, please pre-define it in lib/ib/symbols/#{file}.rb"
				error msg, :symbol
			end
		end
	end
end
