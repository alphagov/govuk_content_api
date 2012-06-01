%w[ lib ].each do |path|
  $:.unshift path unless $:.include?(path)
end

require 'rubygems' 
require 'sinatra'
require 'rabl'
require 'solr_wrapper'

# require 'active_support/core_ext'
# require 'active_support/inflector'
# require 'builder'

# Register RABL
Rabl.register!

set :solr, { server: 'localhost', path: '/solr/rummager', port: 8983}
set :recommended_format, "recommended-link"

def solr
  @solr ||= SolrWrapper.new(DelSolr::Client.new(settings.solr), settings.recommended_format)
end

# Render RABL
get "/search.json" do
  @results = solr.search(params[:q])
  render :rabl, :search, format: "json"
end
