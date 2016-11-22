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
use GdsApi::GovukHeaderSniffer, 'HTTP_GOVUK_ORIGINAL_URL'

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
  metastore_conf = ENV["MEMCACHED_METASTORE"]
  entitystore_conf = ENV["MEMCACHED_ENTITYSTORE"]

  if metastore_conf && entitystore_conf
    use Rack::Cache,
      verbose: true,
      metastore: metastore_conf,
      entitystore: entitystore_conf
  else
    warn "Cache config MEMCACHED_METASTORE, MEMCACHED_ENTITYSTORE not set in env."
  end
end

require 'govuk_content_api'
run GovUkContentApi
