require 'rubygems' 
require 'sinatra'
require 'rabl'
# require 'active_support/core_ext'
# require 'active_support/inflector'
# require 'builder'

# Register RABL
Rabl.register!

# Render RABL
get "/search/:query" do
  @foo = 'blah'
  render :rabl, :search, format: "json"
end