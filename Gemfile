source 'https://rubygems.org'
source 'https://gems.gemfury.com/vo6ZrmjBQu5szyywDszE/'

gem 'rake', '0.9.2.2'
gem 'sinatra', '1.3.2'
gem 'rabl', '0.6.14'
gem 'delsolr', git: 'git://github.com/alphagov/delsolr.git'

if ENV['CONTENT_MODELS_DEV']
  gem 'govuk_content_models', path: '../govuk_content_models'
else
  gem 'govuk_content_models', '0.1.10'
end

gem 'govspeak', '0.8.15'
gem 'factory_girl', '3.3.0'
gem 'database_cleaner', '0.7.2'

group :test do
  gem 'mocha', '0.11.4'
  gem 'simplecov', '0.6.4'
  gem 'test-unit', '2.5.0'
  gem 'ci_reporter', '1.7.0'
end