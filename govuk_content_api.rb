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

# Initialise statsd
statsd = Statsd.new("localhost").tap do |c| c.namespace = "govuk.app.contentapi" end

require "govuk_content_models"
require "govuk_content_models/require_all"


def custom_404
  halt 404, render(:rabl, :not_found, format: "json")
end

def custom_410
  halt 410, render(:rabl, :gone, format: "json")
end

def custom_error(code, message)
  @status = message
  halt code, render(:rabl, :error, format: "json")
end

class Artefact
  attr_accessor :edition, :licence
  field :description, type: String

  scope :live, where(state: 'live')

  def live_related_artefacts
    related_artefacts.live
  end
end

# Render RABL
get "/local_authorities.json" do
  if params[:name]
    name = Regexp.escape(params[:name])
    statsd.time("request.local_authorities.#{name}") do
      @local_authorities = LocalAuthority.where(name: /^#{name}/i).to_a
    end
  elsif params[:snac_code]
    snac_code = Regexp.escape(params[:snac_code])
    statsd.time("request.local_authorities.#{snac_code}") do
      @local_authorities = LocalAuthority.where(snac: /^#{snac_code}/i).to_a
    end
  else
    custom_404
  end

  if @local_authorities.nil? or @local_authorities.empty?
    @local_authorities = []
  end

  search_param = params[:snac_code] || params[:name]
  statsd.time("request.local_authorities.#{search_param}.render") do
    render :rabl, :local_authorities, format: "json"
  end
end

get "/local_authorities/:snac_code.json" do
  if params[:snac_code]
    statsd.time("request.local_authority.#{params[:snac_code]}") do
      @local_authority = LocalAuthority.find_by_snac(params[:snac_code])
    end
  end

  if @local_authority
    statsd.time("request.local_authority.#{params[:snac_code]}.render") do
      render :rabl, :local_authority, format: "json"
    end
  else
    custom_404
  end
end

get "/search.json" do
  begin
    params[:index] ||= 'mainstream'

    if params[:index] == 'mainstream'
      index = SolrWrapper.new(DelSolr::Client.new(settings.mainstream_solr), settings.recommended_format)
    elsif params[:index] == 'whitehall'
      index = SolrWrapper.new(DelSolr::Client.new(settings.inside_solr), settings.recommended_format)
    else
      raise "What do you want?"
    end
    statsd.time("request.search.q.#{params[:q]}") do
      @results = index.search(params[:q])
    end

    statsd.time("request.search.#{params[:q]}.render") do
      render :rabl, :search, format: "json"
    end
  rescue Errno::ECONNREFUSED
    statsd.increment('request.search.unavailable')
    halt 503, render(:rabl, :unavailable, format: "json")
  end
end

get "/tags.json" do
  if params[:type]
    statsd.time("request.tags.type.#{params[:type]}") do
      @tags = Tag.where(tag_type: params[:type])
    end
  else
    statsd.time('request.tags.all') do
      @tags = Tag.all
    end
  end

  render :rabl, :tags, format: "json"
end

get "/tags/:id.json" do
  statsd.time("request.tag.#{params[:id]}") do
    @tag = Tag.where(tag_id: params[:id]).first
  end

  if @tag
    render :rabl, :tag, format: "json"
  else
    custom_404
  end
end

get "/with_tag.json" do
  if params[:include_children].to_i > 1
    @status = "Include children only supports a depth of 1."
    halt 501, render(:rabl, :error, format: "json")
  end

  tag_ids = params[:tag].split(',')
  tags = tag_ids.map { |ti| Tag.where(tag_id: ti).first }.compact

  custom_404 unless tags.length == tag_ids.length

  if params[:include_children]
    tags = Tag.any_in(parent_id: tag_ids)
    tag_ids = tag_ids + tags.map(&:tag_id)
  end

  curated_list = nil
  # Currently only supported sort order is curated
  if params[:sort]
    return custom_404 unless params[:sort] == "curated"
    # Curated list can only be associated with one section
    curated_list = CuratedList.any_in(tag_ids: [tags[0].tag_id]).first
  end

  if curated_list
    @artefacts = curated_list.artefacts
  else
    statsd.time("request.with_tag.multi.#{tag_ids.length}") do
      @artefacts = Artefact.live.any_in(tag_ids: tag_ids)
    end
  end

  if @artefacts.length > 0
    statsd.time('request.with_tag.map_results') do
      # Preload to avoid hundreds of individual queries
      published_editions_for_artefacts = Edition.published.any_in(slug: @artefacts.map(&:slug))
      editions_by_slug = published_editions_for_artefacts.each_with_object({}) do |edition, result_hash|
        result_hash[edition.slug] = edition
      end

      @results = @artefacts.map { |artefact|
        if artefact.owning_app == 'publisher'
          artefact.edition = editions_by_slug[artefact.slug]
          if artefact.edition
            artefact
          else
            nil
          end
        else
          artefact
        end
      }

      @results.compact!
    end
  else
    @results = []
  end

  statsd.time("request.with_tag.render") do
    render :rabl, :with_tag, format: "json"
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

get "/:id.json" do
  verify_unpublished_permission if params[:edition]

  statsd.time("request.id.#{params[:id]}") do
    @artefact = Artefact.where(slug: params[:id]).first
  end
  if params[:edition]
    custom_404 unless @artefact
  else
    if @artefact && @artefact.state == 'archived'
      custom_410 
    end  
    if @artefact.nil? || (@artefact.state != 'live')
      custom_404
    end
  end

  if @artefact.owning_app == 'publisher'
    statsd.time("request.id.#{params[:id]}.edition") do
      @artefact.edition = if params[:edition]
        Edition.where(panopticon_id: @artefact.id, version_number: params[:edition]).first
      else 
        Edition.where(panopticon_id: @artefact.id, state: 'published').first
      end
    end

    if @artefact.edition and @artefact.edition.format == 'Licence'
      begin
        statsd.time("request.id.#{params[:id]}.licence") do
          @artefact.licence = licence_application_api.details_for_licence(@artefact.edition.licence_identifier, params[:snac])
        end
      rescue GdsApi::TimedOutException
        @artefact.licence = { "error" => "timed_out" }
      rescue GdsApi::HTTPErrorResponse
        @artefact.licence = { "error" => "http_error" }
      end
    end

    unless @artefact.edition
      if Edition.where(panopticon_id: @artefact.id, state: 'archived').any?
        custom_410
      else
        custom_404
      end
    end
  end

  statsd.time("request.id.#{params[:id]}.render") do
    render :rabl, :artefact, format: "json"
  end
end
