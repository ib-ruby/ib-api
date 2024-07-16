## define configuration items in spec.yml

require 'bundler/setup'
require 'rspec'
require 'rspec/its'
require 'rspec/given'
require 'rspec/collection_matchers'
require 'ib-api'
require 'pp'
require 'yaml'

# Configure top level option indicating how the test suite should be run

OPTS ||= {
  :verbose => false, #true, # Run test suite in a verbose mode ?
}

# read items from spec.yml 
read_yml = -> (key) do
    YAML::load_file( File.expand_path('../spec.yml',__FILE__))[key]
end


# Configure settings from connect.yml
OPTS[:connection] = read_yml[:connection]
ACCOUNT =  OPTS[:connection][:account]   # shortcut for active account (orders portfolio_values ect.)
SAMPLE =  IB::Stock.new read_yml[:stock]

RSpec.configure do |config|

  puts "Running specs with OPTS:"
  pp OPTS

  # ermöglicht die Einschränkung der zu testenden Specs
  # durch  >>it "irgendwas", :focus => true do <<
  #
  #
  #This configuration allows you to filter to specific examples or groups by tagging
  #them with :focus metadata. When no example or groups are focused (which should be
  #the norm since it's intended to be a temporary change), the filter will be ignored.
  #
  #config.filter_run_including focus: true
  
  #RSpec also provides aliases--fit, fdescribe and fcontext--as a shorthand for
  #it, describe and context with :focus metadata, making it easy to temporarily
  #focus an example or group by prefixing an f.
  config.filter_run_when_matching focus: true

  config.alias_it_should_behave_like_to :it_has_message, 'has message:'
  config.expose_dsl_globally = true  #+ monkey-patching in rspec 3
  config.order = 'defined' # "random"
end
