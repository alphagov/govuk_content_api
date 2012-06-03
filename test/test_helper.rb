require 'govuk_content_api'
require 'test/unit'
require 'rack/test'
require 'mocha'
ENV['RACK_ENV'] = 'test'

class GovUkContentApiTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end
end