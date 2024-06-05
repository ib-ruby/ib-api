
require "zeitwerk"
require "active_model"
require 'active_support/concern'
require 'active_support/core_ext/module/attribute_accessors.rb'
require 'class_extensions'
require 'logger'
require 'terminal-table'

#require 'ib/version'
#require 'ib/connection'

require "server_versions"

require 'ib/constants'
require 'ib/errors'
#loader =  Zeitwerk::Loader.new
loader =  Zeitwerk::Loader.for_gem(warn_on_extra_files: false)
loader.ignore("#{__dir__}/server_versions.rb")
loader.ignore("#{__dir__}/ib_api.rb")
loader.ignore("#{__dir__}/ib/contract.rb")
loader.ignore("#{__dir__}/ib/constants.rb")
loader.ignore("#{__dir__}/ib/errors.rb")
loader.ignore("#{__dir__}/ib/order_condition.rb")
#loader.ignore("#{__dir__}/models")
loader.inflector.inflect(
                         "ib" => "IB",
                         "receive_fa" => "ReceiveFA",
                         "tick_efp" => "TickEFP",
                        )
#loader.push_dir("#{__dir__}")
loader.push_dir("#{__dir__}/../models/")
loader.setup
loader.eager_load
#require 'requires'
require 'ib/contract.rb'
#require 'ib/order_condition.rb'
#IbRuby = Ib
#IB = Ib
