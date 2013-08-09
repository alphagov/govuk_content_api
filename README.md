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
		
## Asset Manager

If your models include media assets such as images and video, you will need to run the asset-manager
app alongside the content api.

See the [asset-manager](http://github.com/alphagov/asset-manager) project for app-specific setup 
instructions.

Content API needs an OAuth bearer token in order to authenticate with Asset Manager. By default, this 
is loaded from the CONTENTAPI_ASSET_MANAGER_BEARER_TOKEN environment variable in config/initializers/gds_api.rb.

To obtain this bearer token, you will first need to generate OAuth keys for the content API application.
In the signonotron2 directory, run:

```
rake applications:create name=contentapi description="content api" home_uri="http://contentapi.dev" redirect_uri="http://contentapi.dev/auth/gds/callback"
```

The provided OAuth tokens should be places into the CONTENTAPI_OAUTH_ID and CONTENTAPI_OAUTH_SECRET environment variables

You can then create an API user in the signonotron2 application. 

```
rake api_clients:create[contentapi,contentapi@example.com,asset-manager,signin]
```

This will generate the bearer token you need.
