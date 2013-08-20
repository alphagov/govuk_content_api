class SearchResultPresenter

  def initialize(result, url_helper)
    @result = result
    @url_helper = url_helper
  end

  def present
    {
      "id" => search_result_url(@result),
      "web_url" => search_result_web_url(@result),
      "title" => @result["title"],
      "details" => {
        "description" => @result["description"]
      }
    }
  end

private
  def search_result_url(result)
    if result['link'].start_with?("http")
      nil
    else
      @url_helper.api_url(result['link']) + ".json"
    end
  end

  def search_result_web_url(result)
    if result['link'].start_with?("http")
      result['link']
    else
      @url_helper.public_web_url(result['link'])
    end
  end
end
