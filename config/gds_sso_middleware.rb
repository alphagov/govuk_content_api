require 'gds-sso'
require 'gds-sso/config'
require 'read_only_user'
require_relative 'gds_sso_config'
require_relative 'secret_token'

# have to provide a session for OmniAuth, but API clients probably won't support that
use Rack::Session::Cookie, secret: SECRET_TOKEN

use ::OmniAuth::Builder do
  provider :gds, ::GDS::SSO::Config.oauth_id, ::GDS::SSO::Config.oauth_secret,
    client_options: {
      site: ::GDS::SSO::Config.oauth_root_url,
      # These don't apply to/don't exist in this app
      # authorize_url: "#{::GDS::SSO::Config.oauth_root_url}/oauth/authorize",
      # token_url: "#{::GDS::SSO::Config.oauth_root_url}/oauth/access_token",
      ssl: { verify: false }
    }
end

use Warden::Manager do |config|
  config.default_strategies :gds_bearer_token
  config.intercept_401 = false # prevent Warden from handling with a non-existent failure_app in the browser
end
