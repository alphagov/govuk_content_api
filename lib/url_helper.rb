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

  def tag_type_url(tag_type, params={})
    url_params = { type: tag_type.singular }.merge(params)
    api_url("/tags.json?#{URI.encode_www_form(url_params)}")
  end

  # This method returns a URL for a tag.
  #
  # The method can be called with an object responding to tag_id and tag_type
  # methods (such as an instance of Tag).
  #
  #   eg. tag = Tag.new(tag_id: "crime", tag_type: "section")
  #             tag_url(tag)  -> "/tags/section/crime.json"
  #
  # It can also be called with the tag_type and tag_id provided as strings.
  #
  #   eg. tag_url("section", "crime")  -> "/tags/section/crime.json"
  #
  def tag_url(tag_or_tag_type, tag_id=nil)
    tag_type = tag_or_tag_type

    if tag_or_tag_type.respond_to?(:tag_type) && tag_or_tag_type.respond_to?(:tag_id)
      tag_type = tag_or_tag_type.tag_type
      tag_id = tag_or_tag_type.tag_id
    end

    api_url("/tags/#{CGI.escape(tag_type)}/#{CGI.escape(tag_id)}.json")
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

  def tag_web_url(tag)
    with_tag_web_url(tag)
  end

  def with_tag_web_url(tag)
    case tag.tag_type
    when "section"
      public_web_url("/browse/#{tag.tag_id}")
    when "specialist_sector"
      public_web_url("/#{tag.tag_id}")
    else
      nil # no public-facing GOV.UK URL exists for other tag types
    end
  end

  def artefacts_by_need_url(need_id, page = nil)
    if page
      api_url("/for_need/#{need_id}.json?" + URI.encode_www_form(page: page))
    else
      api_url("/for_need/#{need_id}.json")
    end
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
