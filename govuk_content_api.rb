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

set :solr, { server: 'localhost', path: '/solr/rummager', port: 8983}
set :recommended_format, "recommended-link"

configure do
   Mongoid.configure do |config|
    name = "govuk_content_development"
    host = "localhost"
    config.master = Mongo::Connection.new.db(name)
    config.persist_in_safe_mode = false
  end
end

def solr
  @solr ||= SolrWrapper.new(DelSolr::Client.new(settings.solr), settings.recommended_format)
end

def locate_gem(name)
  spec = Bundler.load.specs.find{|s| s.name == name }
  raise GemNotFound, "Could not find gem '#{name}' in the current bundle." unless spec
  if spec.name == 'bundler'
    return File.expand_path('../../../', __FILE__)
  end
  spec.full_gem_path
end

$:.unshift  locate_gem('govuk_content_models') + '/app/models'
$:.unshift  locate_gem('govuk_content_models') + '/app/validators'
$:.unshift  locate_gem('govuk_content_models') + '/app/repositories'
Dir.glob(locate_gem('govuk_content_models') + '/app/models/*.rb').each do |f|
  require f
end

class Artefact
  attr_accessor :edition
end

# Render RABL
get "/search.json" do
  @results = solr.search(params[:q])
  content_type :json
  render :rabl, :search, format: "json"
end

get "/tags.json" do
  @tags = Tag.all
  content_type :json
  render :rabl, :tags, format: "json"
end

get "/tag/:id.json" do
  @tag = Tag.where(tag_id: params[:id]).first
  content_type :json
  render :rabl, :tag, format: "json"
end

get "/with_tag.json" do
  @tag = Tag.where(tag_id: params[:tag]).first
  artefacts = Artefact.any_in(tag_ids: [@tag.tag_id])
  @results = artefacts.map { |r|
    if r.owning_app == 'publisher'
      r.edition = Edition.where(slug: r.slug, state: 'published').first
      return nil unless r.edition
    end

    r
  }
  @results.compact!
  content_type :json
  render :rabl, :with_tag, format: "json"
end

get "/:id.json" do
  @artefact = Artefact.where(slug: params[:id]).first

  if @artefact.owning_app == 'publisher'
    @artefact.edition = Edition.where(slug: @artefact.slug, state: 'published').first
    halt 404 unless @artefact.edition
  end
  # TODO: 404 if requesting something that is a publisher item but isn't published
  # TODO: 410 if requesting something that is a publisher item but is only archived
  content_type :json
  render :rabl, :artefact, format: "json"
end
