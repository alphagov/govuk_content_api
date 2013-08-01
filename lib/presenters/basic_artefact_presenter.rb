class BasicArtefactPresenter
  def initialize(artefact, url_helper)
    @artefact = artefact
    @url_helper = url_helper
  end

  def present
    {
      "id" => @url_helper.artefact_url(@artefact),
      "web_url" => @url_helper.artefact_web_url(@artefact),
      "title" => @artefact.name,
      "format" => @artefact.kind
    }
  end
end
