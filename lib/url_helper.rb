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

private
  def plural_tag_type(tag_type)
    if tag_type.respond_to? :plural
      plural_tag_type = tag_type.plural
    else
      # Fall back on the inflector if we have to
      plural_tag_type = tag_type.pluralize
    end
  end
end
