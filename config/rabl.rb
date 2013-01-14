require "rabl"

Rabl.register!

Rabl.configure do |config|
  config.json_engine = :yajl

  # Don't include the bits of extra wrapping that Rabl includes by default,
  # which mean all tags, for example, are wrapped up in an extra
  # '{"tag": { ... }' block.
  config.include_json_root = false
  config.include_child_root = false
end
