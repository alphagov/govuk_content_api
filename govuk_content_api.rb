require 'sinatra'
require 'plek'
require_relative "config"
require 'config/gds_sso_middleware'

class GovUkContentApi < Sinatra::Application
  DEFAULT_CACHE_TIME = 15.minutes.to_i
  LONG_CACHE_TIME = 1.hour.to_i

  ERROR_CODES = {
    401 => "unauthorised",
    403 => "forbidden",
    404 => "not found",
    410 => "gone",
    422 => "unprocessable",
    503 => "unavailable"
  }

  set :views, File.expand_path('views', File.dirname(__FILE__))
  set :show_exceptions, false
  set :protection, except: :path_traversal

  def set_expiry(duration = DEFAULT_CACHE_TIME, options = {})
    visibility = options[:private] ? :private : :public
    expires(duration, visibility)
  end

  before do
    content_type :json
  end

  get "/local_authorities.json" do
    set_expiry LONG_CACHE_TIME
    custom_410
  end

  get "/local_authorities/:snac.json" do
    set_expiry LONG_CACHE_TIME
    custom_410
  end

  get "/tags.json" do
    set_expiry LONG_CACHE_TIME
    custom_410
  end

  get "/tag_types.json" do
    set_expiry LONG_CACHE_TIME
    custom_410
  end

  get "/tags/:tag_type_or_id.json" do
    set_expiry LONG_CACHE_TIME
    custom_410
  end

  get "/tags/:tag_type/*.json" do |tag_type, tag_id|
    set_expiry LONG_CACHE_TIME
    custom_410
  end

  get "/with_tag.json" do
    set_expiry LONG_CACHE_TIME
    custom_410
  end

  get "/*.json" do |id|
    set_expiry LONG_CACHE_TIME
    custom_410
  end

protected

  def custom_410
    custom_error 410, "This item is no longer available"
  end

  def custom_error(code, message)
    error_hash = {
      "_response_info" => {
        "status" => ERROR_CODES.fetch(code),
        "status_message" => message
      }
    }
    halt code, error_hash.to_json
  end
end
