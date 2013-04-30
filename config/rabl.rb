require "rabl"

Rabl.register!

Rabl.configure do |config|
  config.json_engine = :yajl

  # Don't include the bits of extra wrapping that Rabl includes by default,
  # which mean all tags, for example, are wrapped up in an extra
  # '{"tag": { ... }' block.
  config.include_json_root = false
  config.include_child_root = false

  # Cache template source (i.e. only read once off disk) in non-development
  # environments. You can also explicitly set RABL_CACHE=1 to turn on template
  # source caching.
  config.cache_sources = ENV['RABL_CACHE'] || ENV['RACK_ENV'] != 'development'
end
