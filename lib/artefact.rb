require "govuk_content_models"
require "govuk_content_models/require_all"

module ContentApiArtefactExtensions
  extend ActiveSupport::Concern

  included do
    attr_accessor(
      :edition,
      :licence,
      :places,
      :assets,
      :country,
      :extra_related_artefacts,
      :extra_tags,
      :group,
    )
    scope :live, -> { where(state: 'live') }
  end

  def live_tagged_related_artefacts
    groups = related_artefacts_grouped_by_distance(related_artefacts.live)

    related_artefacts = groups.map do |key, artefacts|
      artefacts.each { |a| a.group = key }
    end
    related_artefacts.flatten!

    related_artefacts += @extra_related_artefacts.to_a if @extra_related_artefacts
    related_artefacts.uniq(&:slug)
  end

  def combined_tags(options = {})
    combined_tags = tags(options[:draft])
    combined_tags += @extra_tags.to_a if @extra_tags
    combined_tags.uniq(&:id)
  end
end

class Artefact
  include ContentApiArtefactExtensions
end
