# TaggingsPerApp
#
# Debug helper to aid with the tagging migration. It outputs the taggings for
# a specific app in a hash like:
#
#   { "content_id" => { "mainstream_browse_pages" => ["content_id"]}}
#
class TaggingsPerApp
  # Mapping between the old name used by content_api and the new tag name used
  # in the new publishing world.
  MAP = {
    "section" => "mainstream_browse_pages",
    "organisation" => "organisations",
    "specialist_sector" => "topics",
  }

  def initialize(app_name)
    @app_name = app_name
  end

  def taggings
    relevant_artefacts.each_with_object({}) do |artefact, result|
      result[artefact.content_id] = tags_for_artefact(artefact)
    end
  end

private

  def relevant_artefacts
    Artefact.live.where(owning_app: @app_name, :content_id.nin => [nil])
  end

  def tags_for_artefact(artefact)
    hash = {}

    artefact.tags.map do |tag|
      next unless tag.tag_type.in?(MAP.keys)

      new_type = MAP.fetch(tag.tag_type)
      hash[new_type] ||= []
      hash[new_type] << tag.content_id
    end

    if artefact.primary_section
      hash["parent"] = [artefact.primary_section.content_id]
    end

    hash
  end
end
