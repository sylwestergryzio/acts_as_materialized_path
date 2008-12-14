require File.dirname(__FILE__) + '/../../init';

class Hierarchy < ActiveRecord::Base
  acts_as_materialized_path
end