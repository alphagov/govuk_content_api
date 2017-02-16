class URLHelper
  def initialize(app, website_root, api_prefix, app_lookup = nil)
    # A non-nil value for `app_lookup` implies we want to use app URLs as the
    # web URLs, rather than the `www` host. This is generally development only.

    @website_root = website_root
    @api_prefix = api_prefix
    @app = app

    @app_lookup = app_lookup
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

  def artefact_url(artefact)
    api_url("/#{CGI.escape(artefact.slug)}.json")
  end

  def artefact_web_url(artefact)
    "#{base_web_url(artefact)}/#{artefact.slug}"
  end

private

  def base_web_url(artefact)
    if @app_lookup
      @app_lookup.find(artefact.rendering_app || artefact.owning_app)
    else
      public_web_url
    end
  end
end
