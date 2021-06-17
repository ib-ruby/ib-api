require 'active_support/core_ext/module/attribute_accessors.rb'
require 'extensions/class-extensions'

require 'terminal-table'

require 'ib/version'
require 'ib/errors'
require 'ib/constants'
require 'ib/connection'

# An external model- or database-driver provides the base class for models 
# if the constant DB is defined
# 
# basically 	IB::Model  has to be assigned to the substitute base class
# the database-driver requires models and messages at the appropoate time
unless defined?(DB)
	require 'ib/model' 
	require 'ib/models'
	require 'ib/messages'
end
