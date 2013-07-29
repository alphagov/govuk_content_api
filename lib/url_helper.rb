class URLHelper
  def initialize(app, website_root, api_prefix)
    @website_root = website_root
    @api_prefix = api_prefix
    @app = app
  end

  def api_url(uri)
    if @api_prefix && @api_prefix != ''
      public_web_url("/#{@api_prefix}#{uri}")
    else
      @app.url(uri)
    end
  end

  def public_web_url(path = '')
    @website_root + path
  end
end
