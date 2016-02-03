source 'https://rubygems.org'

gem 'unicorn', '4.9.0'
gem 'rake', '10.4.2'
gem 'sinatra', '1.4.6'

# Pulled in by gds-sso, pinned in order to maintain
# security fixes.
#
# gds-sso should be modified to not require the full
# version of Rails in client applications.
gem 'rails', '3.2.22'

if ENV['CONTENT_MODELS_DEV']
  gem 'govuk_content_models', path: '../govuk_content_models'
else
  gem "govuk_content_models", '~> 32.2'
end

# TODO: This was previously pinned due to a replica set bug in >1.6.2
# Consider whether this still needs to be pinned when it is provided
# as a dependency of govuk_content_models
gem 'mongo', '>= 1.7.1'

gem 'gds-sso', '~> 11.2'

if ENV['API_DEV']
  gem 'gds-api-adapters', :path => '../gds-api-adapters'
else
  gem 'gds-api-adapters', '26.7.0'
end

gem 'govspeak', '~> 3.1'
gem 'plek', '1.10.0'
gem 'yajl-ruby'
gem 'kaminari', '0.14.1'
gem 'link_header', '0.0.8'
gem 'rack-cache', '1.2'
gem 'dalli', '2.7.4'

gem 'rack-logstasher', '0.0.3'
gem 'airbrake', '4.3.0'

group :test do
  gem 'database_cleaner', '1.4.1'
  gem 'factory_girl', '4.5.0'
  gem 'mocha', '0.12.4', require: false
  gem 'simplecov', '0.10.0'
  gem 'simplecov-rcov', '0.2.3'
  gem 'minitest', '3.4.0'
  gem 'turn', require: false
  gem 'ci_reporter', '1.7.0'
  gem 'webmock', '~> 1.21', require: false
  gem 'timecop', '0.7.4'
end

group :development do
  # (Intelligent) reloading server in development
  gem "mr-sparkle", "0.3.0"
end
