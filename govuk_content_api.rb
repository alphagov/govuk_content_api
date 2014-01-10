require 'sinatra'
require 'mongoid'
require 'govspeak'
require 'plek'
require 'gds_api/helpers'
require 'gds_api/rummager'
require_relative "config"
require 'statsd'
require 'config/gds_sso_middleware'
require 'pagination'
require 'tag_types'
require 'ostruct'

require "url_helper"
require "presenters/result_set_presenter"
require "presenters/single_result_presenter"
require "presenters/search_result_presenter"
require "presenters/local_authority_presenter"
require "presenters/tag_presenter"
require "presenters/tag_type_presenter"
require "presenters/basic_artefact_presenter"
require "presenters/minimal_artefact_presenter"
require "presenters/artefact_presenter"
require "presenters/travel_advice_index_presenter"
require "presenters/business_support_scheme_presenter"
require "presenters/licence_presenter"
require "presenters/tagged_artefact_presenter"
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

  def govspeak_formatter
    if params[:content_format] == "govspeak"
      GovspeakFormatter.new(:govspeak, fact_cave_api)
    else
      GovspeakFormatter.new(:html, fact_cave_api)
    end
  end

  def known_tag_types
    @known_tag_types ||= TagTypes.new(Artefact.tag_types)
  end

  def set_expiry(duration = DEFAULT_CACHE_TIME, options = {})
    visibility = options[:private] ? :private : :public
    expires(duration, visibility)
  end

  error Mongo::MongoDBError, Mongo::MongoRubyError do
    statsd.increment("mongo_error")
    raise
  end

  before do
    content_type :json
  end

  get "/local_authorities.json" do
    set_expiry LONG_CACHE_TIME

    search_param = params[:snac] || params[:name]
    @statsd_scope = "request.local_authorities"

    if params[:name]
      name = Regexp.escape(params[:name])
      statsd.time(@statsd_scope) do
        @local_authorities = LocalAuthority.where(name: /^#{name}/i).to_a
      end
    elsif params[:snac]
      snac = Regexp.escape(params[:snac])
      statsd.time(@statsd_scope) do
        @local_authorities = LocalAuthority.where(snac: /^#{snac}/i).to_a
      end
    else
      custom_404
    end

    presenter = ResultSetPresenter.new(
      FakePaginatedResultSet.new(@local_authorities),
      url_helper,
      LocalAuthorityPresenter,
      description: "Local Authorities"
    )

    presenter.present.to_json
  end

  get "/local_authorities/:snac.json" do
    set_expiry LONG_CACHE_TIME

    @statsd_scope = "request.local_authority"
    if params[:snac]
      statsd.time(@statsd_scope) do
        @local_authority = LocalAuthority.find_by_snac(params[:snac])
      end
    end

    if @local_authority
      authority_presenter = LocalAuthorityPresenter.new(
        @local_authority,
        url_helper
      )
      SingleResultPresenter.new(authority_presenter).present.to_json
    else
      custom_404
    end
  end

  get "/search.json" do
    begin
      @statsd_scope = "request.search"
      search_index = params[:index] || 'mainstream'

      unless ['mainstream', 'detailed', 'government'].include?(search_index)
        custom_404
      end

      if params[:q].nil? || params[:q].strip.empty?
        custom_error(422, "Non-empty querystring is required in the 'q' parameter")
      end

      statsd.time(@statsd_scope) do
        search_uri = Plek.current.find('search') + "/#{search_index}"
        client = GdsApi::Rummager.new(search_uri)
        @results = client.search(params[:q])["results"]
      end

      presenter = ResultSetPresenter.new(
        FakePaginatedResultSet.new(@results),
        url_helper,
        SearchResultPresenter
      )

      set_expiry

      presenter.present.to_json
    rescue GdsApi::HTTPErrorResponse, GdsApi::TimedOutException
      custom_503
    end
  end

  get "/tags.json" do
    set_expiry

    @statsd_scope = "request.tags"
    options = {}
    if params[:type]
      options["tag_type"] = params[:type]
    end
    if params[:parent_id]
      options["parent_id"] = params[:parent_id]
    end
    if params[:root_sections]
      options["parent_id"] = nil
    end

    allowed_params = params.slice *%w(type parent_id root_sections sort)

    tags = if options.length > 0
      statsd.time(@statsd_scope) do
        Tag.where(options)
      end
    else
      statsd.time("#{@statsd_scope}.all") do
        Tag
      end
    end

    if params[:sort] and params[:sort] == "alphabetical"
      tags = tags.order_by([:title, :asc])
    end

    if settings.pagination
      begin
        paginated_tags = paginated(tags, params[:page])
      rescue InvalidPage
        # TODO: is it worth recording at a more granular level what's wrong?
        statsd.increment('request.tags.bad_page')
        custom_404
      end

      @result_set = PaginatedResultSet.new(paginated_tags)
      @result_set.populate_page_links { |page_number|
        url_helper.tags_url(allowed_params, page_number)
      }

      headers "Link" => LinkHeader.new(@result_set.links).to_s
    else
      # If the scope is Tag, we need to use Tag.all instead, because the class
      # itself is not a Mongo Criteria object
      tags_scope = tags.is_a?(Class) ? tags.all : tags
      @result_set = FakePaginatedResultSet.new(tags_scope)
    end

    presenter = ResultSetPresenter.new(
      @result_set,
      url_helper,
      TagPresenter,
      # This is replicating the existing behaviour from the old implementation
      # TODO: make this actually describe the results
      description: "All tags"
    )
    presenter.present.to_json
  end

  get "/tag_types.json" do
    set_expiry LONG_CACHE_TIME

    presenter = ResultSetPresenter.new(
      FakePaginatedResultSet.new(known_tag_types),
      url_helper,
      TagTypePresenter,
      description: "All tag types"
    )
    presenter.present.to_json
  end

  get "/tags/:tag_type_or_id.json" do
    set_expiry

    @statsd_scope = "request.tag"

    tag_type = known_tag_types.from_plural(params[:tag_type_or_id])

    # We respond with a 404 to unknown tag types, because the resource of "all
    # tags of type <x>" does not exist when we don't recognise x
    unless tag_type

      # Redirect from a singular tag type to its plural
      # e.g. /tags/section.json => /tags/sections.json
      tag_type = known_tag_types.from_singular(params[:tag_type_or_id])
      redirect(url_helper.tag_type_url(tag_type)) if tag_type

      # Tags used to be accessed through /tags/tag_id.json, so we check here
      # whether one exists to avoid breaking the Web. We only check for section
      # tags, as at the time of change sections were the only tag type in use
      # in production
      section = Tag.by_tag_id(params[:tag_type_or_id], "section")
      redirect(url_helper.tag_url(section)) if section

      custom_404
    end

    @tag_type_name = tag_type.singular
    tags = Tag.where(tag_type: @tag_type_name)

    if @tag_type_name == "section"
      # Extra functionality for sections: roots and parents
      if params[:parent_id] && params[:root_sections]
        custom_404  # Doesn't make sense to have both of these parameters
      end
      if params[:parent_id]
        # Look up parent tag and add to criteria
        if Tag.by_tag_id(params[:parent_id], "section")
          tags = tags.where(parent_id: params[:parent_id])
        else
          custom_404
        end
      end
      if params[:root_sections]
        tags = tags.where(parent_id: nil)
      end
    end

    @result_set = FakePaginatedResultSet.new(tags)

    presenter = ResultSetPresenter.new(
      @result_set,
      url_helper,
      TagPresenter,
      # This description replicates the existing behaviour from the old version
      # TODO: make the description describe the results in all cases
      description: "All '#{@tag_type_name}' tags"
    )
    presenter.present.to_json
  end

  get "/tags/:tag_type/*.json" do |tag_type, tag_id|
    set_expiry

    tag_type = known_tag_types.from_plural(tag_type)
    custom_404 unless tag_type

    @tag = Tag.by_tag_id(tag_id, tag_type.singular)
    if @tag
      tag_presenter = TagPresenter.new(@tag, url_helper)
      SingleResultPresenter.new(tag_presenter).present.to_json
    else
      custom_404
    end
  end

  # Show the artefacts with a given tag
  #
  # Examples:
  #
  #   /with_tag.json?section=crime
  #    - all artefacts in the Crime section
  #   /with_tag.json?section=crime&sort=curated
  #    - all artefacts in the Crime section, with any curated ones first
  get "/with_tag.json" do
    set_expiry

    @statsd_scope = 'request.with_tag'

    unless params[:tag].blank?
      # Old-style tag URLs without types specified

      # If comma-separated tags given, we've stopped supporting that for now
      if params[:tag].include? ","
        custom_404
      end

      # If we can unambiguously determine the tag, redirect to its correct URL
      possible_tags = Tag.where(tag_id: params[:tag]).to_a
      if possible_tags.count == 1
        modifier_params = params.slice('sort')
        redirect url_helper.with_tag_url(possible_tags, modifier_params)
      else
        custom_404
      end
    end

    requested_tags = known_tag_types.each_with_object([]) do |tag_type, req|
      unless params[tag_type.singular].blank?
        req << Tag.by_tag_id(params[tag_type.singular], tag_type.singular)
      end
    end

    # If any of the tags weren't found, that's enough to 404
    custom_404 if requested_tags.any? &:nil?

    # For now, we only support retrieving by a single tag
    custom_404 unless requested_tags.size == 1

    if params[:sort]
      custom_404 unless ["curated", "alphabetical"].include?(params[:sort])
    end

    tag_id = requested_tags.first.tag_id
    tag_type = requested_tags.first.tag_type
    @description = "All content with the '#{tag_id}' #{tag_type}"

    artefacts = sorted_artefacts_for_tag_id(
      tag_id,
      params[:sort]
    )
    results = map_artefacts_and_add_editions(artefacts)
    @result_set = FakePaginatedResultSet.new(results)

    presenter = ResultSetPresenter.new(
      @result_set,
      url_helper,
      TaggedArtefactPresenter,
      description: @description
    )

    presenter.present.to_json
  end

  get "/licences.json" do
    set_expiry

    licence_ids = (params[:ids] || '').split(',')
    if licence_ids.any?
      licences = LicenceEdition.published.in(:licence_identifier => licence_ids)
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

    identifiers = params[:identifiers].to_s.split(",")
    statsd.time("request.business_support_schemes") do
      editions = BusinessSupportEdition.published.in(:business_support_identifier => identifiers)
      @results = editions.map do |ed|
        artefact = Artefact.find(ed.panopticon_id)
        artefact.edition = ed
        artefact
      end
    end

    presenter = ResultSetPresenter.new(
      FakePaginatedResultSet.new(@results),
      url_helper,
      BusinessSupportSchemePresenter
    )
    presenter.present.to_json
  end

  get "/artefacts.json" do
    set_expiry

    artefacts = statsd.time("request.artefacts") do
      Artefact.live.only(MinimalArtefactPresenter::REQUIRED_FIELDS)
    end

    if settings.pagination
      begin
        paginated_artefacts = paginated(artefacts, params[:page])
      rescue InvalidPage
        statsd.increment('request.tags.bad_page')
        custom_404
      end

      @result_set = PaginatedResultSet.new(paginated_artefacts)
      @result_set.populate_page_links { |page_number|
        url_helper.artefacts_url(page_number)
      }
      headers "Link" => LinkHeader.new(@result_set.links).to_s
    else
      @result_set = FakePaginatedResultSet.new(artefacts)
    end

    presenter = ResultSetPresenter.new(
      @result_set,
      url_helper,
      MinimalArtefactPresenter
    )
    presenter.present.to_json
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
      artefacts = Artefact.where(need_id: id)
    else
      artefacts = Artefact.where(need_id: id, state: 'live')
    end

    # This is copied and pasted from the /artefact.json method
    # which suggests we should look to refactor it.
    if settings.pagination
      begin
        paginated_artefacts = paginated(artefacts, params[:page])
      rescue InvalidPage
        statsd.increment('request.for_need.bad_page')
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
      set_expiry(0, :private => true)
    else
      set_expiry
    end

    @statsd_scope = "request.artefact"
    verify_unpublished_permission if params[:edition]

    statsd.time(@statsd_scope) do
      @artefact = Artefact.find_by_slug(id)
    end

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

    if @artefact.owning_app == 'publisher'
      attach_publisher_edition(@artefact, params[:edition])
    elsif @artefact.kind == 'travel-advice'
      attach_travel_advice_country_and_edition(@artefact, params[:edition])
    end

    presenter = SingleResultPresenter.new(
      ArtefactPresenter.new(@artefact, url_helper, govspeak_formatter)
    )

    presenter.present.to_json
  end

  protected

  def map_editions_with_artefacts(editions)
    statsd.time("#{@statsd_scope}.map_editions_to_artefacts") do
      artefact_ids = editions.collect(&:panopticon_id)
      matching_artefacts = Artefact.live.any_in(_id: artefact_ids)

      matching_artefacts.map do |artefact|
        artefact.edition = editions.detect { |e| e.panopticon_id.to_s == artefact.id.to_s }
        artefact
      end
    end
  end

  def map_artefacts_and_add_editions(artefacts)
    statsd.time("#{@statsd_scope}.map_results") do
      # Preload to avoid hundreds of individual queries
      editions_by_slug = published_editions_for_artefacts(artefacts)

      results = artefacts.map do |artefact|
        if artefact.owning_app == 'publisher'
          artefact_with_edition(artefact, editions_by_slug)
        else
          artefact
        end
      end

      results.compact
    end
  end

  def sorted_artefacts_for_tag_id(tag_id, sort)
    statsd.time("#{@statsd_scope}.#{tag_id}") do
      artefacts = Artefact.live.where(tag_ids: tag_id)

      # Load in the curated list and use it as an ordering for the top items in
      # the list. Any artefacts not present in the list go on the end, in
      # alphabetical name order.
      #
      # For example, if the curated list is
      #
      #     [3, 1, 2]
      #
      # and the items have ids
      #
      #     [1, 2, 3, 4, 5]
      #
      # the sorted list will be one of the following:
      #
      #     [3, 1, 2, 4, 5]
      #     [3, 1, 2, 5, 4]
      #
      # depending on the names of artefacts 4 and 5.
      #
      # If the sort order is alphabetical rather than curated, this is
      # equivalent to the special case of curated ordering where the curated
      # list is empty

      if sort == "curated"
        curated_list = CuratedList.where(tag_ids: [tag_id]).first
        first_ids = curated_list ? curated_list.artefact_ids : []
      else
        # Just fall back on alphabetical order
        first_ids = []
      end

      return artefacts.to_a.sort_by { |artefact|
        [
          first_ids.find_index(artefact._id) || first_ids.length,
          artefact.name
        ]
      }
    end
  end

  def published_editions_for_artefacts(artefacts)
    return [] if artefacts.empty?

    slugs = artefacts.map(&:slug)
    published_editions_for_artefacts = Edition.published.any_in(slug: slugs)
    published_editions_for_artefacts.each_with_object({}) do |edition, result_hash|
      result_hash[edition.slug] = edition
    end
  end

  def artefact_with_edition(artefact, editions_by_slug)
    artefact.edition = editions_by_slug[artefact.slug]
    if artefact.edition
      artefact
    else
      nil
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
    statsd.time("#{@statsd_scope}.edition") do
      artefact.edition = if version_number
        Edition.where(panopticon_id: artefact.id, version_number: version_number).first
      else
        Edition.where(panopticon_id: artefact.id, state: 'published').first ||
          Edition.where(panopticon_id: artefact.id).first
      end
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
    if @artefact.edition.is_a?(LocalTransactionEdition) && params[:snac]
      attach_local_information(@artefact, params[:snac])
    end
  end

  def attach_place_data(artefact)
    statsd.time("#{@statsd_scope}.place") do
      artefact.places = imminence_api.places(artefact.edition.place_type, params[:latitude], params[:longitude])
    end
  rescue GdsApi::TimedOutException
    artefact.places = [{ "error" => "timed_out" }]
  rescue GdsApi::HTTPErrorResponse
    artefact.places = [{ "error" => "http_error" }]
  end

  def attach_license_data(artefact)
    statsd.time("#{@statsd_scope}.licence") do
      licence_api_response = licence_application_api.details_for_licence(artefact.edition.licence_identifier, params[:snac])
      artefact.licence = licence_api_response.nil? ? nil : licence_api_response.to_hash
    end

    if artefact.licence and artefact.edition.licence_identifier
      statsd.time("#{@statsd_scope}.licence.local_service") do
        licence_lgsl_code = @artefact.edition.licence_identifier.split('-').first
        artefact.licence['local_service'] = LocalService.where(:lgsl_code => licence_lgsl_code).first
      end
    end
  rescue GdsApi::TimedOutException
    statsd.increment("#{@statsd_scope}.license_request_error.timed_out")
    artefact.licence = { "error" => "timed_out" }
  rescue GdsApi::HTTPErrorResponse
    statsd.increment("#{@statsd_scope}.license_request_error.http")
    artefact.licence = { "error" => "http_error" }
  end

  def attach_travel_advice_country_and_edition(artefact, version_number = nil)
    if artefact.slug =~ %r{\Aforeign-travel-advice/(.*)\z}
      artefact.country = Country.find_by_slug($1)
    end
    custom_404 unless artefact.country

    statsd.time("#{@statsd_scope}.edition") do
      artefact.edition = if version_number
        artefact.country.editions.where(:version_number => version_number).first
      else
        artefact.country.editions.published.first
      end
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
    statsd.time("#{@statsd_scope}.travel_advice_countries") do
      editions = Hash[TravelAdviceEdition.published.all.map {|e| [e.country_slug, e] }]
      @countries = Country.all.map do |country|
        country.tap {|c| c.edition = editions[c.slug] }
      end.reject do |country|
        country.edition.nil?
      end
    end
  end

  def attach_assets(artefact, *fields)
    artefact.assets ||= {}
    fields.each do |key|
      if asset_id = artefact.edition.send("#{key}_id")
        begin
          asset = asset_manager_api.asset(asset_id)
          artefact.assets[key] = asset if asset and asset["state"] == "clean"
        rescue GdsApi::BaseError => e
          logger.warn "Requesting asset #{asset_id} returned error: #{e.inspect}"
        end
      end
    end
  end

  def attach_local_information(artefact, snac)
    provider = artefact.edition.service.preferred_provider(snac)
    artefact.local_authority = provider
    if provider
      artefact.local_interaction = provider.preferred_interaction_for(
        artefact.edition.lgsl_code,
        artefact.edition.lgil_override
      )
    end
  end

  def asset_manager_api
    options = Object::const_defined?(:API_CLIENT_CREDENTIALS) ? API_CLIENT_CREDENTIALS : {
      bearer_token: ENV['CONTENTAPI_ASSET_MANAGER_BEARER_TOKEN']
    }
    super(options)
  end

  # Initialise statsd
  def statsd
    @statsd ||= Statsd.new("localhost").tap do |c|
      c.namespace = ENV['GOVUK_STATSD_PREFIX'].to_s
    end
  end

  def custom_404
    custom_error 404, "Resource not found"
  end

  def custom_410
    custom_error 410, "This item is no longer available"
  end

  def custom_503
    custom_error 503, "A necessary backend process was unavailable. Please try again soon."
  end

  def custom_error(code, message)
    statsd.increment("#{@statsd_scope}.error.#{code}")
    error_hash = {
      "_response_info" => {
        "status" => ERROR_CODES.fetch(code),
        "status_message" => message
      }
    }
    halt code, error_hash.to_json
  end

  def render(*args)
    statsd.time("#{@statsd_scope}.render") do
      super
    end
  end

  def bypass_permission_check?
    (ENV['RACK_ENV'] == "development") && ENV['REQUIRE_AUTH'].nil?
  end

  # Check whether user has permission to see unpublished items
  def check_unpublished_permission
    warden = request.env['warden']
    return true if bypass_permission_check?
    return warden.authenticate? && warden.user.has_permission?("access_unpublished")
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
