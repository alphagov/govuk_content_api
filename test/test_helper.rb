if ENV["USE_SIMPLECOV"]
  require "simplecov"
  require "simplecov-rcov"
  SimpleCov.start 'test_frameworks'
  SimpleCov.formatter = SimpleCov::Formatter::RcovFormatter
end

ENV['RACK_ENV'] = 'test'

$LOAD_PATH << File.expand_path('../../', __FILE__)
$LOAD_PATH << File.expand_path('../../lib', __FILE__)

require 'test/unit'
require 'rack/test'

require 'database_cleaner'
require 'mocha'
require 'shoulda'
require 'factory_girl'
require 'govuk_content_api'
require 'govuk_content_models/test_helpers/factories'

DatabaseCleaner.strategy = :truncation
# initial clean
DatabaseCleaner.clean

module ResponseTestMethods
  def assert_status_field(expected, response)
    assert_equal expected, JSON.parse(response.body)["_response_info"]["status"]
  end
end

class GovUkContentApiTest < Test::Unit::TestCase
  include Rack::Test::Methods
  include ResponseTestMethods

  def app
    Sinatra::Application
  end

  def setup
    DatabaseCleaner.start
  end

  def teardown
    DatabaseCleaner.clean
  end
end
