app_path = File.dirname(__FILE__)
$:.unshift(app_path) unless $:.include?(app_path)
%w[ lib ].each do |path|
  $:.unshift path unless $:.include?(path)
end

require 'rubygems'
require "bundler"
ENV['RACK_ENV'] ||= 'development'
Bundler.require(:default, ENV['RACK_ENV'])

require "logger"

require 'dalli'
require "rack/cache"

use GdsApi::GovukHeaderSniffer, 'HTTP_GOVUK_REQUEST_ID'

in_development = ENV['RACK_ENV'] == 'development'

if in_development
  set :logging, Logger::DEBUG
  # Lets the JS work with different hostnames in development
else
  enable :logging

  log = File.new("log/production.log", "a")
  log.sync = true
  STDOUT.reopen(log)
  STDERR.reopen(log)

  use Rack::Logstasher::Logger,
    Logger.new("log/production.json.log"),
    :extra_request_headers => { "GOVUK-Request-Id" => "govuk_request_id", "x-varnish" => "varnish_id" },
    :extra_response_headers => {"x-rack-cache" => "rack_cache_result"}
end

enable :dump_errors, :raise_errors

if ! in_development || ENV["API_CACHE"]
  cache_config_file_path = File.expand_path(
    "rack-cache.yml",
    File.dirname(__FILE__)
  )
  if File.exists? cache_config_file_path
    use Rack::Cache, YAML.load_file(cache_config_file_path).symbolize_keys
  else
    warn "Cache config file does not exist: #{cache_config_file_path}"
  end
end

require 'govuk_content_api'
run GovUkContentApi
