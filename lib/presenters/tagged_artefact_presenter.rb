require "presenters/basic_artefact_presenter"

class TaggedArtefactPresenter
  def initialize(artefact, url_helper)
    @artefact = artefact
    @url_helper = url_helper
  end

  def present
    base_presenter = BasicArtefactPresenter.new(@artefact, @url_helper)
    base_presenter.present.merge({
      "details" => {
        "description" => @artefact.description
      }
    })
  end
end
