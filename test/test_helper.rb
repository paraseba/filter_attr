require 'rubygems'
require 'test/unit'
require 'active_record'
require 'action_controller'
require 'action_controller/test_case'
require 'action_controller/test_process'

$LOAD_PATH << File.dirname(__FILE__) + '/../lib/'

require 'lib/with_attr'
require 'lib/filter_params'
require 'init'

ActionController::Routing::Routes.reload rescue nil

# some active record methods need a looger initialized
ActiveRecord::Base.logger = Logger.new(STDOUT)
