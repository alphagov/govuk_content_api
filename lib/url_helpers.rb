require "cgi"

module URLHelpers

  def tag_url(tag)
    if tag
      "#{@base_url}/tags/#{CGI.escape(tag.tag_id)}.json"
    else
      nil
    end
  end

  def artefact_url(artefact)
    if artefact
      "#{@base_url}/#{CGI.escape(artefact.slug)}.json"
    else
      nil
    end
  end
end
