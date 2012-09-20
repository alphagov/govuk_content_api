require 'gds-sso'
require 'gds-sso/config'
require 'read_only_user'

::GDS::SSO.config do |config|
  config.user_model     = "ReadOnlyUser"
  config.oauth_id       = 'abcdefghjasndjkasndcontentapi'
  config.oauth_secret   = 'secret'
  config.oauth_root_url = Plek.current.find("signon")
  config.default_scope  = "Content API"
end

 # have to provide a session for OmniAuth, but API clients probably won't support that
use Rack::Session::Cookie

use ::OmniAuth::Builder do
  provider :gds, ::GDS::SSO::Config.oauth_id, ::GDS::SSO::Config.oauth_secret,
    client_options: {
      site: ::GDS::SSO::Config.oauth_root_url,
      authorize_url: "#{::GDS::SSO::Config.oauth_root_url}/oauth/authorize",
      token_url: "#{::GDS::SSO::Config.oauth_root_url}/oauth/access_token",
      ssl: { verify: false }
    }
end

use Warden::Manager do |config|
  config.default_strategies :gds_bearer_token
  config.intercept_401 = false # prevent Warden from handling with a non-existent failure_app in the browser
end
