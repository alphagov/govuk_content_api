class TravelAdviceIndexPresenter
  def initialize(artefact, countries, url_helper, govspeak_formatter)
    @artefact = artefact
    @countries = countries
    @url_helper = url_helper
    @govspeak_formatter = govspeak_formatter
  end

  def present
    artefact_presenter = ArtefactPresenter.new(
      @artefact,
      @url_helper,
      @govspeak_formatter
    )
    presented = artefact_presenter.present
    presented["details"]["countries"] = @countries.map do |c|
      {
        "id" => country_url(c),
        "name" => c.name,
        "identifier" => c.slug,
        "web_url" => country_web_url(c),
        "updated_at" => (c.edition.published_at || c.edition.updated_at).iso8601,
        "change_description" => c.edition.change_description,
        "synonyms" => c.edition.synonyms,
      }
    end

    presented
  end

private
  def country_url(country)
    @url_helper.api_url("/" + CGI.escape("foreign-travel-advice/#{country.slug}.json") )
  end

  def country_web_url(country)
    @url_helper.public_web_url "/foreign-travel-advice/#{country.slug}"
  end
end
