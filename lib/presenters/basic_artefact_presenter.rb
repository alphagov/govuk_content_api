require "presenters/minimal_artefact_presenter"

# Common base presenter for artefacts, including some edition-related
# information such as update dates.
#
# Also presents the `group` field for grouping related artefacts together.
class BasicArtefactPresenter
  def initialize(artefact, url_helper)
    @artefact = artefact
    @url_helper = url_helper
  end

  def present
    presented = MinimalArtefactPresenter.new(@artefact, @url_helper).present
    presented["in_beta"] = !!(@artefact.edition && @artefact.edition.respond_to?(:in_beta?) && @artefact.edition.in_beta?)
    presented["updated_at"] = presented_updated_date.iso8601
    presented["group"] = @artefact.group if @artefact.group.present?
    presented
  end

private
  # Returns the updated date that should be presented to the user
  def presented_updated_date
    updated_options = [@artefact.updated_at]
    updated_options << @artefact.edition.updated_at if @artefact.edition
    updated_options.compact.max
  end
end
