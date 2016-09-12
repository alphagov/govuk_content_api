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
      :group,
    )
    scope :live, -> { where(state: 'live') }
  end

  def live_tagged_related_artefacts
    groups = related_artefacts_grouped_by_distance(related_artefacts.live)

    related_artefacts = groups.map do |key, artefacts|
      artefacts.each { |a| a.group = key }
    end

    related_artefacts.flatten.uniq(&:slug)
  end

  def combined_tags(options = {})
    tags(options[:draft]).uniq(&:id)
  end
end

class Artefact
  include ContentApiArtefactExtensions
end
