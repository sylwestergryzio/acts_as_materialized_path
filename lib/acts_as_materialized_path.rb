$:.unshift(File.dirname(__FILE__)) unless
$:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))
require 'active_record'
require File.dirname(__FILE__) + '/active_record/acts/materialized_path'

module ActsAsMaterializedPath
  ActiveRecord::Base.send :include, ActiveRecord::Acts::MaterializedPath
  VERSION = '0.0.2'
end
