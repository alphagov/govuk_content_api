namespace :router do
  desc "Set up environment details to connect to router"
  task :router_environment do
    require 'router'
    require 'logger'
    @logger = Logger.new STDOUT
    @logger.level = Logger::DEBUG
 
    @router = Router.new "http://router.cluster:8080/router", @logger
    @app_id = 'public-api'
  end
 
  desc "Register the public api proxy in the router"
  task :register_application => :router_environment do
    platform = ENV['FACTER_govuk_platform']
    url = "#{@app_id}.#{platform}.alphagov.co.uk"
    @logger.info "Registering #{@app_id} application against #{url}..."
    @router.update_application @app_id, url
  end
 
  desc "Register /api as a prefix route in the router"
  task :register_routes => [ :router_environment ] do
    url = 'api'
    begin
      @logger.info "Registering prefix route #{url}"
      @router.create_route url, :prefix, @app_id
    rescue => e
      @logger.error "Error registering route: #{e.message}"
      raise
    end
  end
 
  desc "Register public api proxy and routes with the router (run this task on server in cluster)"
  task :register => [ :register_application, :register_routes ]
end
