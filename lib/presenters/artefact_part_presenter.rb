# Present an individual part of a parted edition (one that responds to the
# `order_parts` method; for example, guide editions).
class ArtefactPartPresenter
  def initialize(artefact, part, url_helper, govspeak_formatter)
    @artefact = artefact
    @part = part
    @url_helper = url_helper
    @govspeak_formatter = govspeak_formatter
  end

  def present
    {
      "web_url" => artefact_part_web_url,
      "slug" => @part.slug,
      "order" => @part.order,
      "title" => @part.title,
      "body" => @govspeak_formatter.format(@part.body)
    }
  end

private
  def artefact_part_web_url
    "#{@url_helper.artefact_web_url(@artefact)}/#{@part.slug}"
  end
end
