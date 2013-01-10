require "cgi"

module URLHelpers
  def tags_url(params = {}, page = nil)
    sorted_params = Hash[params.sort]
    url_params = page ? sorted_params.merge(page: page) : sorted_options
    # Not using activesupport's to_query here, because we want to control the
    # order of parameters, specifically so that page comes last.
    api_url("/tags.json?#{URI.encode_www_form(url_params)}")
  end

  def tag_url(tag)
    api_url("/tags/#{CGI.escape(tag.tag_type)}/#{CGI.escape(tag.tag_id)}.json")
  end

  def with_tag_url(tag)
    api_url("/with_tag.json?tag=#{CGI.escape(tag.tag_id)}")
  end

  def with_tag_web_url(tag)
    "#{base_web_search_url}/browse/#{tag.tag_id}"
  end

  def search_result_url(result)
    api_url(result['link']) + ".json"
  end

  def search_result_web_url(result)
    Plek.current.find('www') + result['link']
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
      Plek.current.find('www') + "/#{env['HTTP_API_PREFIX']}#{uri}"
    else
      url(uri)
    end
  end

  def base_web_url(artefact)
    if ["production", "test"].include?(ENV["RACK_ENV"])
      @_base_web_url ||= Plek.current.find('www')
    else
      Plek.current.find(artefact.rendering_app || artefact.owning_app)
    end
  end

  def base_web_search_url
    @_base_web_search_url ||= Plek.current.find('www')
  end

  def local_authority_url(authority)
    api_url("/local_authorities/#{CGI.escape(authority.snac)}.json")
  end
end
