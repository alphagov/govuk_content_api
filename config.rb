require_relative 'env'
require 'airbrake'

configure do
  # Disable pagination until our clients are all ready for it
  disable :pagination
end

initializers_path = File.expand_path('config/initializers/*.rb', File.dirname(__FILE__))
Dir[initializers_path].each { |f| require f }

configure do
  Airbrake.configuration.ignore << "Sinatra::NotFound"
  use Airbrake::Sinatra
end
