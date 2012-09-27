require "cgi"

module URLHelpers
  def tag_url(tag)
    api_url("/tags/#{CGI.escape(tag.tag_id)}.json")
  end

  def with_tag_url(tag)
    api_url("/with_tag.json?tag=#{CGI.escape(tag.tag_id)}")
  end

  def with_tag_web_url(tag)
    "#{base_web_search_url}/browse/#{tag.tag_id}"
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
    env['SCRIPT_NAME'] = env['HTTP_API_PREFIX']
    url(uri)
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
