::GDS::SSO.config do |config|
  config.user_model     = "ReadOnlyUser"
  config.oauth_id       = ENV['CONTENT_API_OAUTH_ID']
  config.oauth_secret   = ENV['CONTENT_API_OAUTH_SECRET']
  config.oauth_root_url = Plek.current.find("signon")
end
