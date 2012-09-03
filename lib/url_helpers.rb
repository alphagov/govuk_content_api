require "cgi"

module URLHelpers

  def tag_url(tag)
    "#{@base_url}/tags/#{CGI.escape(tag.tag_id)}.json"
  end
end
