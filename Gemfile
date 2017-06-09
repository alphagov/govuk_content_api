source 'https://rubygems.org'

gem 'unicorn', '4.9.0'
gem 'rake', '10.4.2'
gem 'sinatra', '1.4.6'

# Pulled in by gds-sso, pinned in order to maintain
# security fixes.
#
# gds-sso should be modified to not require the full
# version of Rails in client applications.
gem 'rails', '4.2.6'

if ENV['CONTENT_MODELS_DEV']
  gem 'govuk_content_models', path: '../govuk_content_models'
else
  gem "govuk_content_models", "~> 42.0.0"
end

gem 'gds-sso', '~> 11.2'

if ENV['API_DEV']
  gem 'gds-api-adapters', path: '../gds-api-adapters'
else
  gem 'gds-api-adapters', '41.2.0'
end

gem 'govspeak', '~> 3.1'
gem 'plek', '1.10.0'
gem 'yajl-ruby'
gem 'link_header', '0.0.8'
gem 'rack-cache', '1.2'
gem 'dalli', '2.7.4'

gem 'rack-logstasher', '0.0.3'
gem 'airbrake', '4.3.0'

group :test do
  gem 'database_cleaner', '1.5.1'
  gem 'factory_girl', '4.5.0'
  gem 'mocha', '1.1.0'
  gem 'simplecov', '0.10.0'
  gem 'simplecov-rcov', '0.2.3'
  gem 'minitest', '~> 5.0'
  gem 'minitest-reporters'
  gem 'ci_reporter_minitest', '1.0.0'
  gem 'webmock', '~> 1.21', require: false
  gem 'timecop', '0.7.4'
end

group :development do
  # (Intelligent) reloading server in development
  gem "mr-sparkle", "0.3.0"
end

group :development, :test do
  gem 'govuk-lint'
end
