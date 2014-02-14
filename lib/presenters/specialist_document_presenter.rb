class SpecialistDocumentPresenter
  def initialize(artefact, url_helper)
    @artefact = artefact
    @url_helper = url_helper
  end

  def present
    MinimalArtefactPresenter.new(@artefact, @url_helper).present.merge(
      'summary' => @artefact.edition.summary
    )
  end
end
