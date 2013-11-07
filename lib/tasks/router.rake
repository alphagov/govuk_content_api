namespace :router do
  desc "Set up environment details to connect to router"
  task :router_environment do
    require 'plek'
    require 'gds_api/router'

    @router_api = GdsApi::Router.new Plek.current.find('router-api')
    @app_id = 'publicapi'
  end

  desc "Register the public api proxy in the router"
  task :register_backend => :router_environment do
    url = Plek.current.find(@app_id, :force_http => true) + "/"
    puts "Registering #{@app_id} application against #{url}"
    @router_api.add_backend @app_id, url
  end

  desc "Register /api as a prefix route in the router"
  task :register_routes => [ :router_environment ] do
    path = '/api'
    begin
      puts "Registering prefix route #{path}"
      @router_api.add_route(path, 'prefix', @app_id)
    rescue => e
      puts "Error registering route: #{e.message}"
      raise
    end
  end

  desc "Register public api proxy and routes with the router (run this task on server in cluster)"
  task :register => [ :register_backend, :register_routes ]
end
