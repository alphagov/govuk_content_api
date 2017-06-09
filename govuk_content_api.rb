require 'sinatra'
require 'mongoid'
require 'govspeak'
require 'plek'
require 'gds_api/helpers'
require_relative "config"
require 'config/gds_sso_middleware'
require 'ostruct'

require "url_helper"
require "presenters/result_set_presenter"
require "presenters/single_result_presenter"
require "presenters/basic_artefact_presenter"
require "presenters/minimal_artefact_presenter"
require "presenters/artefact_presenter"
require "presenters/travel_advice_index_presenter"
require "govspeak_formatter"

# Note: the artefact patch needs to be included before the Kaminari patch,
# otherwise it doesn't work. I haven't quite got to the bottom of why that is.
require 'artefact'
require 'config/kaminari'
require 'country'
require 'services'

class GovUkContentApi < Sinatra::Application
  helpers GdsApi::Helpers

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

  def url_helper
    parameters = [self, Plek.current.website_root, env['HTTP_API_PREFIX']]

    # When running in development mode we may want the URL for the item
    # as served directly by the app that provides it. We can trigger this by
    # providing the current Plek instance to the URL helper.
    if ENV["RACK_ENV"] == "development"
      parameters << Plek.current
    end

    URLHelper.new(*parameters)
  end

  def govspeak_formatter(options = {})
    if params[:content_format] == "govspeak"
      GovspeakFormatter.new(:govspeak, options)
    else
      GovspeakFormatter.new(:html, options)
    end
  end

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
    # The edition param is for accessing unpublished editions in order for
    # editors to preview them. These can change frequently and so shouldn't be
    # cached.
    if params[:edition]
      set_expiry(0, private: true)
    else
      set_expiry
    end

    verify_unpublished_permission if params[:edition]

    @artefact = Artefact.find_by_slug(id)

    custom_404 unless @artefact
    handle_unpublished_artefact(@artefact) unless params[:edition]

    if @artefact.slug == 'foreign-travel-advice'
      load_travel_advice_countries
      presenter = SingleResultPresenter.new(
        TravelAdviceIndexPresenter.new(
          @artefact,
          @countries,
          url_helper,
          govspeak_formatter
        )
      )
      return presenter.present.to_json
    end

    formatter_options = {}

    presenters = [SingleResultPresenter]

    if @artefact.owning_app == 'publisher'
      attach_publisher_edition(@artefact, params[:edition])
    elsif @artefact.kind == 'travel-advice'
      attach_travel_advice_country_and_edition(@artefact, params[:edition])
    end

    base_presented_artefact = ArtefactPresenter.new(
      @artefact,
      url_helper,
      govspeak_formatter(formatter_options),
    )

    presented_artefact = presenters
      .reduce(base_presented_artefact) { |composed_presenter, presenter_class|
        presenter_class.new(composed_presenter)
      }

    presented_artefact.present.to_json
  end

protected

  def handle_unpublished_artefact(artefact)
    if artefact.state == 'archived'
      custom_410
    elsif artefact.state != 'live'
      custom_404
    end
  end

  def attach_publisher_edition(artefact, version_number = nil)
    artefact.edition = if version_number
                         Edition.where(panopticon_id: artefact.id, version_number: version_number).first
                       else
                         Edition.where(panopticon_id: artefact.id, state: 'published').first ||
                           Edition.where(panopticon_id: artefact.id).first
                       end

    if version_number && artefact.edition.nil?
      custom_404
    end
    if artefact.edition && version_number.nil?
      if artefact.edition.state == 'archived'
        custom_410
      elsif artefact.edition.state != 'published'
        custom_404
      end
    end

    attach_assets(@artefact, :caption_file) if @artefact.edition.is_a?(VideoEdition)
    attach_assets(@artefact, :small_image, :medium_image, :large_image) if @artefact.edition.is_a?(CampaignEdition)
  end

  def attach_travel_advice_country_and_edition(artefact, version_number = nil)
    if artefact.slug =~ %r{\Aforeign-travel-advice/(.*)\z}
      artefact.country = Country.find_by_slug($1)
    end
    custom_404 unless artefact.country

    artefact.edition = if version_number
                         artefact.country.editions.where(version_number: version_number).first
                       else
                         artefact.country.editions.published.first
                       end
    custom_404 unless artefact.edition
    attach_assets(artefact, :image, :document)
  end

  def load_travel_advice_countries
    editions = Hash[TravelAdviceEdition.published.all.map { |e| [e.country_slug, e] }]
    @countries = Country.all.map do |country|
      country.tap { |c| c.edition = editions[c.slug] }
    end
    @countries = @countries.reject do |country|
      country.edition.nil?
    end
  end

  def attach_assets(artefact, *fields)
    artefact.assets ||= {}
    fields.each do |key|
      asset_id = artefact.edition.send("#{key}_id")
      if asset_id
        begin
          asset = Services.asset_manager.asset(asset_id)
          artefact.assets[key] = asset if asset && asset["state"] == "clean"
        rescue GdsApi::BaseError => e
          logger.warn "Requesting asset #{asset_id} returned error: #{e.inspect}"
        end
      end
    end
  end

  def custom_404
    custom_error 404, "Resource not found"
  end

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

  def bypass_permission_check?
    (ENV['RACK_ENV'] == "development") && ENV['REQUIRE_AUTH'].nil?
  end

  # Generate error response when user doesn't have permission to see unpublished items
  def verify_unpublished_permission
    warden = request.env['warden']
    return if bypass_permission_check?
    if warden.authenticate?
      if warden.user.has_permission?("access_unpublished")
        return true
      else
        custom_error(403, "You must be authorized to use the edition parameter")
      end
    end

    custom_error(401, "Edition parameter requires authentication")
  end
end
