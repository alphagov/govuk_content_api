require 'sinatra'
require 'mongoid'
require 'govspeak'
require 'plek'
require 'gds_api/helpers'
require_relative "config"
require 'config/gds_sso_middleware'
require 'pagination'
require 'ostruct'

require "url_helper"
require "presenters/result_set_presenter"
require "presenters/single_result_presenter"
require "presenters/tag_presenter"
require "presenters/basic_artefact_presenter"
require "presenters/minimal_artefact_presenter"
require "presenters/artefact_presenter"
require "presenters/travel_advice_index_presenter"
require "presenters/business_support_scheme_presenter"
require "presenters/licence_presenter"
require "govspeak_formatter"

# Note: the artefact patch needs to be included before the Kaminari patch,
# otherwise it doesn't work. I haven't quite got to the bottom of why that is.
require 'artefact'
require 'config/kaminari'
require 'country'

class GovUkContentApi < Sinatra::Application
  helpers GdsApi::Helpers

  include Pagination

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

  get "/licences.json" do
    set_expiry

    licence_ids = (params[:ids] || '').split(',')
    if licence_ids.any?
      licences = LicenceEdition.published.in(licence_identifier: licence_ids)
      @results = map_editions_with_artefacts(licences)
    else
      @results = []
    end

    @result_set = FakePaginatedResultSet.new(@results)
    presenter = ResultSetPresenter.new(
      @result_set,
      url_helper,
      LicencePresenter,
      description: "Licences"
    )
    presenter.present.to_json
  end

  get "/business_support_schemes.json" do
    set_expiry

    facets = {}
    [:area_gss_codes, :business_sizes, :locations, :purposes, :sectors, :stages, :support_types].each do |key|
      facets[key] = params[key] if params[key].present?
    end

    if facets.empty?
      editions = BusinessSupportEdition.published
    else
      editions = BusinessSupportEdition.for_facets(facets).published
    end

    editions = editions.order_by({ priority: :desc }, title: :asc)

    @results = editions.map do |ed|
      artefact = Artefact.find(ed.panopticon_id)
      artefact.edition = ed
      artefact
    end
    @results.select!(&:live?)

    presenter = ResultSetPresenter.new(
      FakePaginatedResultSet.new(@results),
      url_helper,
      BusinessSupportSchemePresenter
    )
    presenter.present.to_json
  end

  get "/artefacts.json" do
    set_expiry
    custom_410
  end

  # Show the artefacts for a given need ID
  #
  # Authenticated users with the appropriate permission will get all matching
  # artefacts. Unauthenticated or unauthorized users will just get the currently
  # live artefacts.
  #
  # Examples:
  #
  #   /for_need/123.json
  #    - all artefacts with the need_id 123
  get "/for_need/:id.json" do |id|
    set_expiry

    if check_unpublished_permission
      artefacts = Artefact.any_in(need_ids: [id])
    else
      artefacts = Artefact.live.any_in(need_ids: [id])
    end

    # This is copied and pasted from the /artefact.json method
    # which suggests we should look to refactor it.
    if settings.pagination
      begin
        paginated_artefacts = paginated(artefacts, params[:page])
      rescue InvalidPage
        custom_404
      end

      result_set = PaginatedResultSet.new(paginated_artefacts)
      result_set.populate_page_links { |page_number|
        url_helper.artefacts_by_need_url(id, page_number)
      }
      headers "Link" => LinkHeader.new(result_set.links).to_s
    else
      result_set = FakePaginatedResultSet.new(artefacts)
    end

    presenter = ResultSetPresenter.new(
      result_set,
      url_helper,
      MinimalArtefactPresenter
    )
    presenter.present.to_json
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
      draft_tags: params[:draft_tags]
    )

    presented_artefact = presenters
      .reduce(base_presented_artefact) { |composed_presenter, presenter_class|
        presenter_class.new(composed_presenter)
      }

    presented_artefact.present.to_json
  end

protected

  def map_editions_with_artefacts(editions)
    artefact_ids = editions.collect(&:panopticon_id)
    matching_artefacts = Artefact.live.any_in(_id: artefact_ids)

    matching_artefacts.map do |artefact|
      artefact.edition = editions.detect { |e| e.panopticon_id.to_s == artefact.id.to_s }
      artefact
    end
  end

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

    attach_place_data(@artefact) if @artefact.edition.format == "Place" && params[:latitude] && params[:longitude]
    attach_license_data(@artefact) if @artefact.edition.format == 'Licence'
    attach_assets(@artefact, :caption_file) if @artefact.edition.is_a?(VideoEdition)
    attach_assets(@artefact, :small_image, :medium_image, :large_image) if @artefact.edition.is_a?(CampaignEdition)
  end

  def attach_place_data(artefact)
    artefact.places = imminence_api.places(artefact.edition.place_type, params[:latitude], params[:longitude])
  rescue GdsApi::TimedOutException
    artefact.places = [{ "error" => "timed_out" }]
  rescue GdsApi::HTTPErrorResponse
    artefact.places = [{ "error" => "http_error" }]
  end

  def attach_license_data(artefact)
    licence_api_response = licence_application_api.details_for_licence(artefact.edition.licence_identifier, params[:snac])
    artefact.licence = licence_api_response.nil? ? nil : licence_api_response.to_hash

    if artefact.licence && artefact.edition.licence_identifier
      licence_lgsl_code = @artefact.edition.licence_identifier.split('-').first
      artefact.licence['local_service'] = LocalService.where(lgsl_code: licence_lgsl_code).first
    end
  rescue GdsApi::TimedOutException
    artefact.licence = { "error" => "timed_out" }
  rescue => e
    Airbrake.notify_or_ignore(e)
    artefact.licence = { "error" => "http_error" }
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

    travel_index = Artefact.find_by_slug("foreign-travel-advice")
    unless travel_index.nil?
      artefact.extra_related_artefacts = travel_index.live_tagged_related_artefacts
      artefact.extra_tags = travel_index.tags
    end
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
          asset = asset_manager_api.asset(asset_id)
          artefact.assets[key] = asset if asset && asset["state"] == "clean"
        rescue GdsApi::BaseError => e
          logger.warn "Requesting asset #{asset_id} returned error: #{e.inspect}"
        end
      end
    end
  end

  def asset_manager_api
    options = Object::const_defined?(:ASSET_MANAGER_API_CREDENTIALS) ? ASSET_MANAGER_API_CREDENTIALS : {
      bearer_token: ENV['CONTENTAPI_ASSET_MANAGER_BEARER_TOKEN']
    }
    super(options)
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

  # Check whether user has permission to see unpublished items
  def check_unpublished_permission
    warden = request.env['warden']
    return true if bypass_permission_check?
    warden.authenticate? && warden.user.has_permission?("access_unpublished")
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
