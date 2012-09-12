require "cgi"

module URLHelpers

  def tag_url(tag)
    url("/tags/#{CGI.escape(tag.tag_id)}.json")
  end

  def with_tag_url(tag)
    url("/with_tag.json?tag=#{CGI.escape(tag.tag_id)}")
  end

  def with_tag_web_url(tag)
    url("/browse/#{tag.tag_id}")
  end

  def artefact_url(artefact)
    url("/#{CGI.escape(artefact.slug)}.json")
  end

  def artefact_web_url(artefact)
    url("/#{artefact.slug}")
  end

  def base_web_url(artefact)
    if ["production", "test"].include?(ENV["RACK_ENV"])
      @_base_web_url ||= Plek.current.find('www')
    else
      Plek.current.find(artefact.rendering_app || artefact.owning_app)
    end
  end

  def base_web_search_url
    if ["production", "test"].include?(ENV["RACK_ENV"])
      @_base_web_search_url ||= Plek.current.find('www')
    else
      @_base_web_search_url ||= Plek.current.find('search')
    end
  end
end
