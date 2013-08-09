::GDS::SSO.config do |config|
  config.user_model     = "ReadOnlyUser"
  config.oauth_id       = ENV['CONTENTAPI_OAUTH_ID'] || 'abcdefghjasndjkasndcontentapi'
  config.oauth_secret   = ENV['CONTENTAPI_OAUTH_SECRET'] || 'secret'
  config.oauth_root_url = Plek.current.find("signon")
end
