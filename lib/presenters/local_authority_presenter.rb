class LocalAuthorityPresenter

  FIELDS = %w(
    name snac tier homepage_url
  )

  def initialize(result, url_helper)
    @result = result
    @url_helper = url_helper
  end

  def present
    presented = {
      "id" => local_authority_url(@result),
    }

    FIELDS.each_with_object(presented) do |field_name, hash|
      hash[field_name] = @result.send(field_name)
    end

    presented
  end

private
  def local_authority_url(authority)
    @url_helper.api_url("/local_authorities/#{CGI.escape(authority.snac)}.json")
  end
end
