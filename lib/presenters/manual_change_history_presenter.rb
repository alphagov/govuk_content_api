class ManualChangeHistoryPresenter
  def initialize(artefact_presenter)
    @artefact_presenter = artefact_presenter
  end

  def edition
    @artefact_presenter.edition
  end

  def present(*args, &block)
    orig = @artefact_presenter.present(*args, &block)

    orig.merge(
      "details" => orig.fetch("details").merge(history_fields),
    )
  end

  private

  def history_fields
    {
      "updates" => edition.updates,
      "manual_slug" => edition.manual_slug,
    }
  end
end
