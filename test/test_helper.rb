ENV['RACK_ENV'] = 'test'

require "bundler"
Bundler.require(:default, ENV['RACK_ENV'])

require 'simplecov'
SimpleCov.start

require_relative '../govuk_content_api'
require 'test/unit'
require 'rack/test'
require 'database_cleaner'
require 'mocha'
require 'factory_girl'
require 'govuk_content_models/test_helpers/factories'

DatabaseCleaner.strategy = :truncation
# initial clean
DatabaseCleaner.clean

class GovUkContentApiTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def clean_db
  	DatabaseCleaner.clean
  end

  def setup
  	self.clean_db
  end

  def teardown
  	self.clean_db
  end

end