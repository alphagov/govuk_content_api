class SpecialistDocumentPresenter
  def initialize(artefact_presenter)
    @artefact_presenter = artefact_presenter
  end

  def edition
    @artefact_presenter.edition
  end

  def present(*args, &block)
    orig = @artefact_presenter.present(*args, &block)

    orig.merge(
      "details" => orig
        .fetch("details")
        .merge(document_specific_details),
    )
  end

private

  def document_specific_details
    rendered_document.details
  end

  def rendered_document
    edition
  end
end
