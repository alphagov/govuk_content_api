::GDS::SSO.config do |config|
  config.user_model     = "ReadOnlyUser"
  config.oauth_id       = 'abcdefghjasndjkasndcontentapi'
  config.oauth_secret   = 'secret'
  config.oauth_root_url = Plek.current.find("signon")
end
