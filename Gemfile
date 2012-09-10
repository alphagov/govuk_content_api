source 'https://rubygems.org'
source 'https://gems.gemfury.com/vo6ZrmjBQu5szyywDszE/'

gem 'unicorn', '~> 4.3.1'
gem 'rake', '0.9.2.2'
gem 'sinatra', '1.3.2'
gem 'rabl', '0.6.14'
gem 'delsolr', git: 'https://github.com/alphagov/delsolr.git'
gem 'statsd-ruby', '1.0.0'

if ENV['CONTENT_MODELS_DEV']
  gem 'govuk_content_models', path: '../govuk_content_models'
else
  gem 'govuk_content_models', '1.6.2'
end

gem 'govspeak', '0.8.15'
gem 'factory_girl', '3.6.1'
gem 'database_cleaner', '0.7.2'
gem 'plek', '0.3.0'
gem 'router-client', '3.1.0', :require => false

group :development, :test do
  gem 'mocha', '0.12.3', require: false
  gem 'shoulda', '3.1.1'
  gem 'simplecov', '0.6.4'
  gem 'simplecov-rcov', '0.2.3'
  gem 'minitest', '3.3.0'
  gem 'ci_reporter', '1.7.0'
end

group :development do
  gem "shotgun"
end