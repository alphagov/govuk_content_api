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

  def tags_url(params = {}, page = nil)
    sorted_params = Hash[params.sort]
    url_params = page ? sorted_params.merge(page: page) : sorted_options
    # Not using activesupport's to_query here, because we want to control the
    # order of parameters, specifically so that page comes last.
    api_url("/tags.json?#{URI.encode_www_form(url_params)}")
  end

  def tag_type_url(tag_type)
    api_url("/tags/#{CGI.escape(plural_tag_type(tag_type))}.json")
  end

  def tag_url(tag)
    plural = plural_tag_type(tag.tag_type)
    api_url("/tags/#{CGI.escape(plural)}/#{CGI.escape(tag.tag_id)}.json")
  end

  def with_tag_url(tag_or_tags, params = {})
    tags = tag_or_tags.is_a?(Array) ? tag_or_tags : [tag_or_tags]
    tags_by_type = tags.group_by &:tag_type
    if tags_by_type.values.any? { |t| t.count > 1 }
      raise ArgumentError, "Cannot search by multiple tags of one type"
    end

    # e.g. {"section" => "crime", "keyword" => "robbery"}
    tag_query = Hash[tags_by_type.map { |tag_type, tags_of_type|
      [tag_type, tags_of_type.first.tag_id]
    }]

    tag_query = Hash[tag_query.sort].merge(Hash[params.sort])

    api_url("/with_tag.json?#{URI.encode_www_form(tag_query)}")
  end

  def with_tag_web_url(tag)
    public_web_url("/browse/#{tag.tag_id}")
  end

  def artefacts_url(page = nil)
    if page
      api_url("/artefacts.json?" + URI.encode_www_form(page: page))
    else
      api_url("/artefacts.json")
    end
  end

  def artefact_url(artefact)
    api_url("/#{CGI.escape(artefact.slug)}.json")
  end

  def artefact_web_url(artefact)
    "#{base_web_url(artefact)}/#{artefact.slug}"
  end

private
  def plural_tag_type(tag_type)
    if tag_type.respond_to? :plural
      plural_tag_type = tag_type.plural
    else
      # Fall back on the inflector if we have to
      plural_tag_type = tag_type.pluralize
    end
  end

  def base_web_url(artefact)
    if @app_lookup
      @app_lookup.find(artefact.rendering_app || artefact.owning_app)
    else
      public_web_url
    end
  end
end
