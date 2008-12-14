require 'active_record'
require File.dirname(__FILE__) + '/lib/active_record/acts/materialized_path'
ActiveRecord::Base.send :include, ActiveRecord::Acts::MaterializedPath