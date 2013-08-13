require "presenters/basic_artefact_presenter"

class LicencePresenter
  def initialize(licence, url_helper)
    @licence = licence
    @url_helper = url_helper
  end

  def present
    base_presenter = BasicArtefactPresenter.new(@licence, @url_helper)

    base_presenter.present.merge({
      "details" => {
        "licence_identifier" => @licence.edition.licence_identifier,
        "licence_short_description" => @licence.edition.licence_short_description
      }
    })
  end
end
