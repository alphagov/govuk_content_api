%w[ lib ].each do |path|
  $:.unshift path unless $:.include?(path)
end

require 'rubygems' 
require 'sinatra'
require 'rabl'
require 'solr_wrapper'
require 'mongoid'

# require 'active_support/core_ext'
# require 'active_support/inflector'
# require 'builder'

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
# Render RABL
get "/search.json" do
  @results = solr.search(params[:q])
  render :rabl, :search, format: "json"
end

get "/tags.json" do
  @tags = Tag.all
  render :rabl, :tags, format: "json"
end

get "/tag/:id.json" do
  @tag = Tag.where(tag_id: params[:id]).first
  render :rabl, :tag, format: "json"
end

get "/with_tag.json" do
  @tag = Tag.where(tag_id: params[:tag]).first
  @results = Artefact.any_in(tag_ids: [@tag.tag_id])
  @results.map! { |r|
    if Edition.where(panopticon_id: r.id).any?
      r.edition = Edition.where(panopticon_id: r.id).first.published_edition
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
  render :rabl, :with_tag, format: "json"
end

get "/:id.json" do
  @artefact = Artefact.where(slug: params[:id]).first
  @edition = Edition.where(panopticon_id: @artefact.id).first.published_edition
  # TODO: 404 if requesting something that is a publisher item but isn't published
  # TODO: 410 if requesting something that is a publisher item but is only archived
  render :rabl, :artefact, format: "json"
end
