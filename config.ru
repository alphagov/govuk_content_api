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

in_development = ENV['RACK_ENV'] == 'development'
in_preview = ENV['FACTER_govuk_platform'] == 'preview'

if in_development or in_preview
  set :logging, Logger::DEBUG
else
  enable :logging
end

enable :dump_errors, :raise_errors

unless in_development
  log = File.new("log/sinatra.log", "a")
  STDOUT.reopen(log)
  STDERR.reopen(log)
end

require 'govuk_content_api'
run GovUkContentApi