begin
  require 'spec'
rescue LoadError
  require 'rubygems'
  gem 'rspec'
  require 'spec'
end

$:.unshift(File.dirname(__FILE__) + '/test_models/')
require 'hierarchy'
$:.unshift(File.dirname(__FILE__) + '/test_database/')
require 'database_connection'
require 'migrations'