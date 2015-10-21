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
      "area_gss_codes" => @artefact.edition.area_gss_codes,
      "business_sizes" => @artefact.edition.business_sizes,
      "locations" => @artefact.edition.locations,
      "purposes" => @artefact.edition.purposes,
      "sectors" => @artefact.edition.sectors,
      "stages" => @artefact.edition.stages,
      "support_types" => @artefact.edition.support_types
    })
  end
end
