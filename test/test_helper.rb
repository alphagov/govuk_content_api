ENV['RACK_ENV'] = 'test'
ENV['GOVUK_WEBSITE_ROOT'] ||= 'https://www.gov.uk'

$LOAD_PATH << File.expand_path('../../', __FILE__)
$LOAD_PATH << File.expand_path('../../lib', __FILE__)

require 'minitest/autorun'
require 'rack/test'
require 'govuk_content_api'

module ResponseTestMethods
  def assert_status_field(expected, response)
    assert_equal expected, JSON.parse(response.body)["_response_info"]["status"]
  end

  def assert_status_message(expected, response)
    assert_equal expected, JSON.parse(response.body)["_response_info"]["status_message"]
  end
end

class GovUkContentApiTest < MiniTest::Spec
  include Rack::Test::Methods
  include ResponseTestMethods

  def app
    GovUkContentApi
  end

  def public_web_url
    ENV['GOVUK_WEBSITE_ROOT']
  end
end
