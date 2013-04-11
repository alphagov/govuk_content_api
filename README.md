# GOV.UK Content API

The content API provides a read-only API layer to access information about any
content on GOV.UK; it is how front-end applications (such as
[frontend](https://github.com/alphagov/frontend) and
[Smart Answers](https://github.com/alphagov/smart-answers)) access content,
metadata and search.

## Testing

Run the following to ensure your environment is set up correctly:

    bundle install && bundle exec rake

## Caching

To enable caching in development, you'll need to pick a caching backend by
symlinking one of the Rack::Cache config files. For instance, to set up a
memory-backed cache:

    ln -s rack-cache.heap.yml rack-cache.yml

Then, to run the server:

    API_CACHE=1 bundle exec rackup -p 3022

If you have access to the development repository, run

    API_CACHE=1 bowl contentapi

or

    API_CACHE=1 foreman start contentapi
