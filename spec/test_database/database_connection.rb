require 'active_record'
database_configuration = YAML.load_file File.dirname(__FILE__) + "/database_configuration.yml"
ActiveRecord::Base.establish_connection(database_configuration)