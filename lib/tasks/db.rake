
namespace :db do
  task :drop do
    require 'mongoid'

    mongoid_config_file = File.expand_path("../../../mongoid.yml", __FILE__)
    unless File.exist?(mongoid_config_file)
      raise "Can't find mongoid config in #{mongoid_config_file}"
    end
    ::Mongoid.load!(mongoid_config_file)
    ::Mongoid::Clients.default.database.drop
  end
end
