class ManualArtefactPresenter
  def initialize(artefact_presenter)
    @artefact_presenter = artefact_presenter
  end

  def edition
    @artefact_presenter.edition
  end

  def present(*args, &block)
    orig = @artefact_presenter.present(*args, &block)

    orig.merge(
      "details" => orig.fetch("details").merge(manual_fields),
    )
  end

  private

  def manual_fields
    {
      "section_groups" => @artefact_presenter.edition.section_groups,
    }
  end
end
