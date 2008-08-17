require 'rubygems'
require 'test/unit'
require 'active_record'
require File.join(File.dirname(__FILE__), '../lib/with_attr')
require File.join(File.dirname(__FILE__), '../init')

# some active record methods need a looger initialized
ActiveRecord::Base.logger = Logger.new(STDOUT)
