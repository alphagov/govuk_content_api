class LocalAuthorityPresenter

  FIELDS = %w(
    name snac tier homepage_url
  )

  def initialize(result)
    @result = result
  end

  def present
    FIELDS.each_with_object({}) do |field_name, hash|
      hash[field_name] = @result.send(field_name)
    end
  end
end
