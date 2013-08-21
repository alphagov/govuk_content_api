# Presenter showing the minimum information to identify an artefact.
#
# This notably doesn't access any edition information, so we can safely use it
# in the artefact list where we don't want to look up any extra information
# across collections.
class MinimalArtefactPresenter
  def initialize(artefact, url_helper)
    @artefact = artefact
    @url_helper = url_helper
  end

  def present
    {
      "id" => @url_helper.artefact_url(@artefact),
      "web_url" => @url_helper.artefact_web_url(@artefact),
      "title" => edition_or_artefact_title,
      "format" => edition_or_artefact_format,
    }
  end

private
  def edition_or_artefact_title
    if @artefact.edition and @artefact.edition.respond_to?(:title)
      @artefact.edition.title
    else
      @artefact.name
    end
  end

  def edition_or_artefact_format
    if @artefact.edition and @artefact.edition.respond_to?(:format)
      @artefact.edition.format.underscore
    else
      @artefact.kind
    end
  end
end
