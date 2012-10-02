require 'sinatra'
require 'rabl'
require 'solr_wrapper'
require 'mongoid'
require 'govspeak'
require 'plek'
require 'url_helpers'
require 'content_format_helpers'
require 'gds_api/helpers'
require_relative "config"
require 'statsd'
require 'config/gds_sso_middleware'
require 'models'

class GovUkContentApi < Sinatra::Application
  helpers URLHelpers, GdsApi::Helpers, ContentFormatHelpers

  set :views, File.expand_path('views', File.dirname(__FILE__))

  # Register RABL
  Rabl.register!
  Rabl.configure do |c|
    c.json_engine = :yajl
  end

  before do
    content_type :json
  end

  # Render RABL
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
      params[:index] ||= 'mainstream'

      if params[:index] == 'mainstream'
        index = SolrWrapper.new(DelSolr::Client.new(settings.mainstream_solr), settings.recommended_format)
      elsif params[:index] == 'whitehall'
        index = SolrWrapper.new(DelSolr::Client.new(settings.inside_solr), settings.recommended_format)
      else
        raise "What do you want?"
      end
      statsd.time(@statsd_scope) do
        @results = index.search(params[:q])
      end

      render :rabl, :search, format: "json"
    rescue Errno::ECONNREFUSED
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
    if options.length > 0
      statsd.time("#{@statsd_scope}.options.#{options}") do
        @tags = Tag.where(options)
      end
    else
      statsd.time("#{@statsd_scope}.all") do
        @tags = Tag.all
      end
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

    if params[:include_children].to_i > 1
      custom_error(501, "Include children only supports a depth of 1.")
    end
    if params[:sort]
      custom_404 unless ["curated", "alphabetical"].include?(params[:sort])
    end
    tag_ids = collect_tag_ids(params[:tag], params[:include_children])
    artefacts = sorted_artefacts_for_tag_ids(tag_ids, params[:sort])
    @results = map_artefacts_and_add_editions(artefacts)

    render :rabl, :with_tag, format: "json"
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

  get "/:id.json" do
    @statsd_scope = "request.id.#{params[:id]}"
    verify_unpublished_permission if params[:edition]

    statsd.time("#{@statsd_scope}") do
      @artefact = Artefact.where(slug: params[:id]).first
    end

    custom_404 unless @artefact
    handle_unpublished_artefact(@artefact) unless params[:edition]

    if @artefact.owning_app == 'publisher'
      attach_publisher_edition(@artefact, params[:edition])
    end

    render :rabl, :artefact, format: "json"
  end

  protected
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
    if sort == "curated"
      curated_list = nil
      if sort
        # Curated list can only be associated with one section
        curated_list = CuratedList.any_in(tag_ids: [tag_ids.first]).first
      end

      if curated_list
        artefacts = curated_list.artefacts
      else
        statsd.time("#{@statsd_scope}.multi.#{tag_ids.length}") do
          artefacts = Artefact.live.any_in(tag_ids: tag_ids)
        end
      end
    else
      statsd.time("#{@statsd_scope}.multi.#{tag_ids.length}") do
        artefacts = Artefact.live.any_in(tag_ids: tag_ids).order_by(:name, :asc)
      end
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

    attach_license_data(@artefact) if @artefact.edition.format == 'Licence'
  end

  def attach_license_data(artefact)
    statsd.time("#{@statsd_scope}.licence") do
      artefact.licence = licence_application_api.details_for_licence(@artefact.edition.licence_identifier, params[:snac])
    end
  rescue GdsApi::TimedOutException
    statsd.increment("#{@statsd_scope}.license_request_error.timed_out")
    artefact.licence = { "error" => "timed_out" }
  rescue GdsApi::HTTPErrorResponse
    statsd.increment("#{@statsd_scope}.license_request_error.http")
    artefact.licence = { "error" => "http_error" }
  end

  # Initialise statsd
  def statsd
    @statsd ||= Statsd.new("localhost").tap do |c|
      c.namespace = "govuk.app.contentapi"
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
    if warden.authenticate?
      if warden.user.has_permission?(GDS::SSO::Config.default_scope, "access_unpublished")
        return true
      else
        custom_error(403, "You must be authorized to use the edition parameter")
      end
    end

    custom_error(401, "Edition parameter requires authentication")
  end
end
