
namespace :db do

  task :drop do
    require 'mongoid'

    mongoid_config_file = File.expand_path("../../../mongoid.yml", __FILE__)
    unless File.exists?(mongoid_config_file)
      raise "Can't find mongoid config in #{mongoid_config_file}"
    end
    ::Mongoid.load!(mongoid_config_file)

    # Taken from https://github.com/mongoid/mongoid/blob/2.6.0-stable/lib/mongoid/railties/database.rake#L172-L175
    ::Mongoid.master.collections.select {|c| c.name !~ /system/ }.each { |c| c.drop }
  end
end
