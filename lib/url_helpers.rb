require "cgi"

module URLHelpers
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

  def search_result_url(result)
    if result['link'].start_with?("http")
      nil
    else
      api_url(result['link']) + ".json"
    end
  end

  def search_result_web_url(result)
    if result['link'].start_with?("http")
      result['link']
    else
      public_web_url(result['link'])
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

  def artefact_part_web_url(artefact, part)
    "#{artefact_web_url(artefact)}/#{part.slug}"
  end

  def api_url(uri)
    if env['HTTP_API_PREFIX'] && env['HTTP_API_PREFIX'] != ''
      public_web_url("/#{env['HTTP_API_PREFIX']}#{uri}")
    else
      url(uri)
    end
  end

  def public_web_url(path = '')
    Plek.current.website_root + path
  end

  # When running in development mode we may want the URL for the item
  # as served directly by the app that provides it. This method applies
  # that switch
  def base_web_url(artefact)
    if ["production", "test"].include?(ENV["RACK_ENV"])
      public_web_url
    else
      Plek.current.find(artefact.rendering_app || artefact.owning_app)
    end
  end

  def local_authority_url(authority)
    api_url("/local_authorities/#{CGI.escape(authority.snac)}.json")
  end

  def country_url(country)
    api_url("/" + CGI.escape("foreign-travel-advice/#{country.slug}.json") )
  end

  def country_web_url(country)
    public_web_url "/foreign-travel-advice/#{country.slug}"
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
