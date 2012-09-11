%w[ lib ].each do |path|
  $:.unshift path unless $:.include?(path)
end

require 'sinatra'
require 'rabl'
require 'solr_wrapper'
require 'mongoid'
require 'govspeak'
require 'plek'
require 'url_helpers'
require_relative "config"
require 'statsd'

helpers URLHelpers

set :views, File.expand_path('views', File.dirname(__FILE__))

# Register RABL
Rabl.register!

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

class Artefact
  attr_accessor :edition
  field :description, type: String
end

def format_content(string)
  if @content_format == "html"
    Govspeak::Document.new(string, auto_ids: false).to_html
  else
    string
  end
end

# Render RABL
get "/local_authorities.json" do
  content_type :json

  if params[:council]
    council = params[:council].to_s.gsub(/[^0-9a-z ]/i, '')
    unless council.empty?
      statsd.time("request.local_authorities.#{council}") do
        @local_authorities = LocalAuthority.where(name: /^#{council}/i).to_a
      end
    end
  elsif params[:snac_code]
    snac_code = params[:snac_code].to_s.gsub(/[^0-9a-z ]/i, '')
    unless snac_code.empty?
      statsd.time("request.local_authorities.#{snac_code}") do
        @local_authorities = LocalAuthority.where(snac: /^#{snac_code}/i).to_a
      end
    end
  end

  if @local_authorities && @local_authorities.any?
    search_param = params[:snac_code] || params[:council]
    statsd.time("request.local_authorities.#{search_param}.render") do
      render :rabl, :local_authorities, format: "json"
    end
  else
    custom_404
  end
end

get "/local_authority/:snac_code.json" do
  content_type :json

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

    content_type :json
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

  content_type :json
  render :rabl, :tags, format: "json"
end

get "/tags/:id.json" do
  statsd.time("request.tag.#{params[:id]}") do
    @tag = Tag.where(tag_id: params[:id]).first
  end
  content_type :json

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

  statsd.time("request.with_tag.multi.#{tag_ids.length}") do
    @artefacts = Artefact.any_in(tag_ids: tag_ids)
  end

  statsd.time('request.with_tag.map_results') do
    @results = @artefacts.map { |r|
      if r.owning_app == 'publisher'
        r.edition = Edition.where(slug: r.slug, state: 'published').first
        if r.edition
          r
        else
          nil
        end
      else
        r
      end
    }

    @results.compact!
  end

  content_type :json
  statsd.time("request.with_tag.render") do
    render :rabl, :with_tag, format: "json"
  end
end

get "/:id.json" do
  statsd.time("request.id.#{params[:id]}") do
    @artefact = Artefact.where(slug: params[:id]).first
  end
  custom_404 unless @artefact

  @content_format = (params[:content_format] == "govspeak") ? "govspeak" : "html"

  if @artefact.owning_app == 'publisher'
    statsd.time("request.id.#{params[:id]}.edition") do
      @artefact.edition = Edition.where(slug: @artefact.slug, state: 'published').first
    end
    unless @artefact.edition
      if Edition.where(slug: @artefact.slug, state: 'archived').any?
        custom_410
      else
        custom_404
      end
    end
  end

  content_type :json
  statsd.time("request.id.#{params[:id]}.render") do
    render :rabl, :artefact, format: "json"
  end
end
