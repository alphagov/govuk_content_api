require "presenters/minimal_artefact_presenter"

class BusinessSupportSchemePresenter
  def initialize(artefact, url_helper)
    @artefact = artefact
    @url_helper = url_helper
  end

  def present
    base_presenter = MinimalArtefactPresenter.new(@artefact, @url_helper)

    base_presenter.present.merge({
      "short_description" => @artefact.edition.short_description,
      "identifier" => @artefact.edition.business_support_identifier
    })
  end
end
