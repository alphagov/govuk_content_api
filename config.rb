require_relative 'env'

def config_for(kind)
  if ! File.exists?(File.expand_path("../#{kind}.yml", __FILE__))
    puts "ERMAHGERD #{File.expand_path("../#{kind}.yml", __FILE__)} doesn't exist"
  end
  YAML.load_file(File.expand_path("../#{kind}.yml", __FILE__))
end

set :mainstream_solr, config_for(:mainstream_solr)[ENV["RACK_ENV"]]
set :inside_solr,     config_for(:inside_solr)[ENV["RACK_ENV"]]
set :recommended_format, "recommended-link"

configure do
  mongoid_config_file = File.expand_path("mongoid.yml", File.dirname(__FILE__))
  if File.exists?(mongoid_config_file)
    ::Mongoid.load!(mongoid_config_file)
  end
end