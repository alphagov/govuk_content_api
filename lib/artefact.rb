require "govuk_content_models"
require "govuk_content_models/require_all"

module ContentApiArtefactExtensions
  extend ActiveSupport::Concern

  included do
    attr_accessor :edition, :licence, :places, :assets, :country, :extra_related_artefacts
    scope :live, where(state: 'live')
  end

  def live_related_artefacts
    artefacts = ordered_related_artefacts(related_artefacts.live)
  end

  def live_grouped_related_artefacts
    artefacts = related_artefacts_grouped_by_distance(related_artefacts.live)
    artefacts["other"] += @extra_related_artefacts.to_a if @extra_related_artefacts
    artefacts["other"].uniq!(&:slug)
    artefacts
  end

end

class Artefact
  include ContentApiArtefactExtensions
end
