require "cgi"

module URLHelpers

  def tag_url(tag)
    if tag
      "#{@base_api_url}/tags/#{CGI.escape(tag.tag_id)}.json"
    else
      nil
    end
  end

  def tag_web_url(tag)
    if tag
      "#{@base_search_url}/browse/#{CGI.escape(tag.tag_id)}"
    else
      nil
    end
  end

  def artefact_url(artefact)
    if artefact
      "#{@base_api_url}/#{CGI.escape(artefact.slug)}.json"
    else
      nil
    end
  end
end
