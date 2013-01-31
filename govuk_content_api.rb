require 'sinatra'
require 'rabl'
require 'mongoid'
require 'govspeak'
require 'plek'
require 'url_helpers'
require 'content_format_helpers'
require 'timestamp_helpers'
require 'gds_api/helpers'
require 'gds_api/rummager'
require_relative "config"
require 'statsd'
require 'config/gds_sso_middleware'
require 'pagination'

# Note: the artefact patch needs to be included before the Kaminari patch,
# otherwise it doesn't work. I haven't quite got to the bottom of why that is.
require 'artefact'
require 'config/kaminari'
require 'config/rabl'
require 'country'

class GovUkContentApi < Sinatra::Application
  helpers URLHelpers, GdsApi::Helpers, ContentFormatHelpers, TimestampHelpers

  include Pagination

  set :views, File.expand_path('views', File.dirname(__FILE__))
  set :show_exceptions, false

  error Mongo::MongoDBError, Mongo::MongoRubyError do
    statsd.increment("mongo_error")
    raise
  end

  before do
    content_type :json
  end

  get "/local_authorities.json" do
    search_param = params[:snac] || params[:name]
    @statsd_scope = "request.local_authorities.#{search_param}"

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

    @result_set = FakePaginatedResultSet.new(@local_authorities)

    render :rabl, :local_authorities, format: "json"
  end

  get "/local_authorities/:snac.json" do
    @statsd_scope = "request.local_authority.#{params[:snac]}"
    if params[:snac]
      statsd.time(@statsd_scope) do
        @local_authority = LocalAuthority.find_by_snac(params[:snac])
      end
    end

    if @local_authority
      render :rabl, :local_authority, format: "json"
    else
      custom_404
    end
  end

  get "/search.json" do
    begin
      @statsd_scope = "request.search.q.#{params[:q]}"
      search_index = params[:index] || 'mainstream'

      unless ['mainstream', 'detailed', 'government'].include?(search_index)
        custom_404
      end

      statsd.time(@statsd_scope) do
        search_uri = Plek.current.find('search') + "/#{search_index}"
        client = GdsApi::Rummager.new(search_uri)
        @results = client.search(params[:q])
      end

      render :rabl, :search, format: "json"
    rescue GdsApi::Rummager::SearchServiceError, GdsApi::Rummager::SearchTimeout
      statsd.increment('request.search.unavailable')
      halt 503, render(:rabl, :unavailable, format: "json")
    end
  end

  get "/tags.json" do
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

    allowed_params = params.slice *%w(type parent_id root_sections)

    tags = if options.length > 0
      statsd.time("#{@statsd_scope}.options.#{options}") do
        Tag.where(options)
      end
    else
      statsd.time("#{@statsd_scope}.all") do
        Tag
      end
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
        tags_url(allowed_params, page_number)
      }

      headers "Link" => LinkHeader.new(@result_set.links).to_s
    else
      # If the scope is Tag, we need to use Tag.all instead, because the class
      # itself is not a Mongo Criteria object
      tags_scope = tags.is_a?(Class) ? tags.all : tags
      @result_set = FakePaginatedResultSet.new(tags_scope)
    end

    render :rabl, :tags, format: "json"
  end

  get "/tags/:id.json" do
    @statsd_scope = "request.tag.#{params[:id]}"
    statsd.time(@statsd_scope) do
      @tag = Tag.where(tag_id: params[:id]).first
    end

    if @tag
      render :rabl, :tag, format: "json"
    else
      custom_404
    end
  end

  get "/with_tag.json" do
    @statsd_scope = 'request.with_tag'

    custom_404 if params[:tag].nil? || params[:tag].empty?

    if params[:include_children].to_i > 1
      custom_error(501, "Include children only supports a depth of 1.")
    end
    if params[:sort]
      custom_404 unless ["curated", "alphabetical"].include?(params[:sort])
    end
    tag_ids = collect_tag_ids(params[:tag], params[:include_children])
    artefacts = sorted_artefacts_for_tag_ids(tag_ids, params[:sort])
    results = map_artefacts_and_add_editions(artefacts)
    @result_set = FakePaginatedResultSet.new(results)

    render :rabl, :with_tag, format: "json"
  end

  get "/licences.json" do
    licence_ids = (params[:ids] || '').split(',')
    if licence_ids.any?
      licences = LicenceEdition.published.in(:licence_identifier => licence_ids)
      @results = map_editions_with_artefacts(licences)
    else
      @results = []
    end

    @result_set = FakePaginatedResultSet.new(@results)

    render :rabl, :licences, format: "json"
  end

  get "/business_support_schemes.json" do
    identifiers = params[:identifiers].to_s.split(",")
    statsd.time("request.business_support_schemes") do
      editions = BusinessSupportEdition.published.in(:business_support_identifier => identifiers)
      @results = editions.map do |ed|
        artefact = Artefact.find(ed.panopticon_id)
        artefact.edition = ed
        artefact
      end
    end
    render :rabl, :business_support_schemes, format: "json"
  end

  get "/travel-advice.json" do
    @countries = attach_edition_to_countries Country.all
    render :rabl, :travel_advice, format: "json"
  end

  get "/artefacts.json" do
    artefacts = statsd.time("request.artefacts") do
      Artefact.live
    end

    if settings.pagination
      begin
        paginated_artefacts = paginated(artefacts, params[:page])
      rescue InvalidPage
        statsd.increment('request.tags.bad_page')
        custom_404
      end

      @result_set = PaginatedResultSet.new(paginated_artefacts)
      @result_set.populate_page_links { |page_number| artefacts_url(page_number) }
      headers "Link" => LinkHeader.new(@result_set.links).to_s
    else
      @result_set = FakePaginatedResultSet.new(artefacts)
    end

    render :rabl, :artefacts, format: "json"
  end

  get "/:id.json" do
    @statsd_scope = "request.artefact"
    verify_unpublished_permission if params[:edition]

    slug = CGI.unescape(params[:id])
    @artefact = load_artefact(slug)

    custom_404 unless @artefact
    handle_unpublished_artefact(@artefact) unless params[:edition]

    if @artefact.owning_app == 'publisher'
      attach_publisher_edition(@artefact, params[:edition])
    elsif @artefact.kind == 'travel-advice'
      attach_travel_advice_edition(@artefact, params[:edition])
    end

    render :rabl, :artefact, format: "json"
  end

  protected

  def load_artefact(slug)
    artefact = nil
    statsd.time(@statsd_scope) do
      artefact = Artefact.find_by_slug(slug)
    end

    # Travel advice has a different required behaviour to other artefacts:
    # The request should only 404 if the requested country doesn't exist.
    #
    # Otherwise if there is no live artefact, a mostly blank response should
    # be returned that includes the country details.
    if slug =~ %r{\Atravel-advice/(.*)\z}
      country = Country.find_by_slug($1)
      custom_404 unless country

      if artefact and artefact.live?
        artefact.country = country
      else
        artefact = build_blank_travel_advice_artefact(country)
      end
    end

    artefact
  end

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

  def collect_tag_ids(tag_list, include_children)
    tag_ids = params[:tag].split(',')
    # TODO: Can this be done with a single query?
    tags = tag_ids.map { |ti| Tag.where(tag_id: ti).first }.compact

    custom_404 unless tags.length == tag_ids.length

    if params[:include_children]
      tags = Tag.any_in(parent_id: tag_ids)
      tag_ids = tag_ids + tags.map(&:tag_id)
    end

    tag_ids
  end

  def sorted_artefacts_for_tag_ids(tag_ids, sort)
    statsd.time("#{@statsd_scope}.multi.#{tag_ids.length}") do
      artefacts = Artefact.live.any_in(tag_ids: tag_ids)

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
        curated_list = CuratedList.any_in(tag_ids: [tag_ids.first]).first
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

    if artefact.edition && version_number.nil?
      if artefact.edition.state == 'archived'
        custom_410
      elsif artefact.edition.state != 'published'
        custom_404
      end
    end

    attach_place_data(@artefact) if @artefact.edition.format == "Place" && params[:latitude] && params[:longitude]
    attach_license_data(@artefact) if @artefact.edition.format == 'Licence'
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

  def attach_edition_to_countries(countries)
    editions = Hash[TravelAdviceEdition.published.all.map {|e| [e.country_slug, e] }]
    countries.map do |country|
      country.tap {|c| c.edition = editions[c.slug] }
    end
  end

  def build_blank_travel_advice_artefact(country)
    artefact = Artefact.new(
      :kind => "travel-advice",
      :slug => "travel-advice/#{country.slug}",
      :name => country.name,
      :owning_app => 'travel-advice-publisher',
      :state => 'live',
      :updated_at => Time.now
    )
    artefact.country = country
    artefact
  end

  def attach_travel_advice_edition(artefact, version_number = nil)
    statsd.time("#{@statsd_scope}.edition") do
      artefact.edition = if version_number
        artefact.country.editions.where(:version_number => version_number).first
      else
        artefact.country.editions.published.first
      end
    end
  end

  # Initialise statsd
  def statsd
    @statsd ||= Statsd.new("localhost").tap do |c|
      c.namespace = ENV['GOVUK_STATSD_PREFIX'].to_s
    end
  end

  def custom_404
    statsd.increment("#{@statsd_scope}.error.404")
    halt 404, render(:rabl, :not_found, format: "json")
  end

  def custom_410
    statsd.increment("#{@statsd_scope}.error.410")
    halt 410, render(:rabl, :gone, format: "json")
  end

  def custom_error(code, message)
    @status = message
    statsd.increment("#{@statsd_scope}.error.#{code}")
    halt code, render(:rabl, :error, format: "json")
  end

  def render(*args)
    statsd.time("#{@statsd_scope}.render") do
      super
    end
  end

  def verify_unpublished_permission
    warden = request.env['warden']
    return if (ENV['RACK_ENV'] == "development") && ENV['REQUIRE_AUTH'].nil?
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
