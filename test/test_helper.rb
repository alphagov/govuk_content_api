if ENV["USE_SIMPLECOV"]
  require "simplecov"
  require "simplecov-rcov"
  SimpleCov.start 'test_frameworks'
  SimpleCov.formatter = SimpleCov::Formatter::RcovFormatter
end

ENV['RACK_ENV'] = 'test'
ENV['GOVUK_WEBSITE_ROOT'] ||= 'https://www.gov.uk'

$LOAD_PATH << File.expand_path('../../', __FILE__)
$LOAD_PATH << File.expand_path('../../lib', __FILE__)

require 'minitest/autorun'
require 'rack/test'

require 'database_cleaner'
require 'mocha/mini_test'
require 'factory_girl'
require 'webmock/minitest'
require 'timecop'
require 'govuk_content_api'
require 'govuk_content_models/test_helpers/factories'
require 'gds_api/test_helpers/json_client_helper'

require 'minitest/reporters'
Minitest::Reporters.use!(
  Minitest::Reporters::SpecReporter.new(color: true),
)

DatabaseCleaner.strategy = :truncation
# initial clean
DatabaseCleaner.clean

WebMock.disable_net_connect!

module ResponseTestMethods
  def assert_status_field(expected, response)
    assert_equal expected, JSON.parse(response.body)["_response_info"]["status"]
  end

  def assert_status_message(expected, response)
    assert_equal expected, JSON.parse(response.body)["_response_info"]["status_message"]
  end

  def assert_base_artefact_fields(parsed_response)
    assert_equal 'ok', parsed_response["_response_info"]["status"]
    assert_has_expected_fields(parsed_response, %w(title id tags))
  end

  def assert_has_expected_fields(parsed_response, fields)
    fields.each do |field|
      assert parsed_response.has_key?(field), "Field #{field} is MISSING. Fields were: #{parsed_response.keys}"
    end
  end

  def assert_has_values(parsed_response, value_hash)
    value_hash.each do |key, value|
      assert_equal value, parsed_response[key], "Incorrect value for key #{key.inspect}"
    end
  end

  # Check for a page with the given relationship in the Link header
  def assert_link(rel, href, response = last_response)
    link_header = LinkHeader.parse(response.headers["Link"])
    found_link = link_header.find_link(["rel", rel])
    assert found_link, "No link with rel '#{rel}' found"
    assert_equal href, found_link.href

    # Also check in _response_info
    parsed_response = JSON.parse(response.body)
    links = parsed_response.fetch("_response_info", {})["links"] || []
    found_link = links.find { |link| link["rel"] == rel }
    assert found_link, "No link with rel '#{rel}' found in _response_info"
    assert_equal href, found_link["href"]
  end

  # Ensure there is no link with the given relationship in the Link header
  def refute_link(rel, response = last_response)
    link_header = LinkHeader.parse(response.headers["Link"])
    found_link = link_header.find_link(["rel", rel])
    refute found_link, "Unexpected link with rel '#{rel} found"

    # Also check in _response_info
    parsed_response = JSON.parse(response.body)
    links = parsed_response.fetch("_response_info", {})["links"] || []
    found_link = links.find { |link| link["rel"] == rel }
    refute found_link, "Unexpected link with rel '#{rel} in _response_info"
  end
end

class MiniTest::Spec
  before :each do
    DatabaseCleaner.start
  end

  after :each do
    DatabaseCleaner.clean
    Timecop.return
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

Country.data_path = File.expand_path("../fixtures/data/countries.yml", __FILE__)
