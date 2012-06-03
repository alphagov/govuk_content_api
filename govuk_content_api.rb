%w[ lib ].each do |path|
  $:.unshift path unless $:.include?(path)
end

require 'rubygems' 
require 'sinatra'
require 'rabl'
require 'solr_wrapper'
require 'mongoid'
require 'govspeak'

# Register RABL
Rabl.register!

set :mainstream_solr, { server: 'localhost', path: '/solr/rummager', port: 8983}
set :inside_solr,  { server: 'localhost', path: '/solr/whitehall-rummager', port: 8983}
set :recommended_format, "recommended-link"

configure do
   Mongoid.configure do |config|
    name = "govuk_content_development"
    host = "localhost"
    config.master = Mongo::Connection.new.db(name)
    config.persist_in_safe_mode = false
  end
end

def locate_gem(name)
  spec = Bundler.load.specs.find{|s| s.name == name }
  raise GemNotFound, "Could not find gem '#{name}' in the current bundle." unless spec
  spec.full_gem_path
end

def custom_404
  halt 404, render(:rabl, :not_found, format: "json")
end

def custom_410
  halt 410, render(:rabl, :gone, format: "json")
end

$:.unshift locate_gem('govuk_content_models') + '/app/models'
$:.unshift locate_gem('govuk_content_models') + '/app/validators'
$:.unshift locate_gem('govuk_content_models') + '/app/repositories'
Dir.glob(locate_gem('govuk_content_models') + '/app/models/*.rb').each do |f|
  require f
end

class Artefact
  attr_accessor :edition
  field :description, type: String
end

# Render RABL
get "/search.json" do
  begin
    indices = []
    if params[:index].nil? || params[:index] == 'mainstream'
      indices << SolrWrapper.new(DelSolr::Client.new(settings.mainstream_solr), settings.recommended_format)
    end

    if params[:index].nil? || params[:index] == 'inside'
      indices << SolrWrapper.new(DelSolr::Client.new(settings.inside_solr), settings.recommended_format)
    end

    @results = indices.map { |i| i.search(params[:q]) }.flatten

    content_type :json
    render :rabl, :search, format: "json"
  rescue Errno::ECONNREFUSED
    halt 503, render(:rabl, :unavailable, format: "json")
  end
end

get "/tags.json" do
  if params[:type]
    @tags = Tag.where(tag_type: params[:type])
  else
    @tags = Tag.all
  end

  content_type :json
  render :rabl, :tags, format: "json"
end

get "/tags/:id.json" do
  @tag = Tag.where(tag_id: params[:id]).first
  content_type :json

  if @tag
    render :rabl, :tag, format: "json"
  else
    custom_404
  end
end

get "/with_tag.json" do
  tag_ids = params[:tag].split(',')
  tags = tag_ids.map { |ti| Tag.where(tag_id: ti).first }.compact

  custom_404 unless tags.length == tag_ids.length

  artefacts = Artefact.any_in(tag_ids: tag_ids)

  @results = artefacts.map { |r|
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


  content_type :json
  render :rabl, :with_tag, format: "json"
end

get "/:id.json" do
  @artefact = Artefact.where(slug: params[:id]).first

  custom_404 unless @artefact

  if @artefact.owning_app == 'publisher'
    @artefact.edition = Edition.where(slug: @artefact.slug, state: 'published').first
    unless @artefact.edition
      if Edition.where(slug: @artefact.slug, state: 'archived').any?
        custom_410
      else
        custom_404
      end
    end
  end

  content_type :json
  render :rabl, :artefact, format: "json"
end
