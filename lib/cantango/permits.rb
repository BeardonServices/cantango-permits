require 'bundler/setup'

require 'sugar-high/array'
require 'sugar-high/blank'
require 'hashie'
require 'sweetloader'

require 'cantango/config'
require 'cantango/core'
require 'cantango/api'

SweetLoader.namespaces = {:CanTango => 'cantango'}
SweetLoader.mode = :require

module CanTango
  sweetload :License, :Permit, :Executor
end

require 'cantango/permits_ext'

module CanTango
  module Permit
    sweetload :Base, :Attribute
    sweetload :UserType, :AccountType, :Special, :User
  end
end
