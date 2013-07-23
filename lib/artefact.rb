require "govuk_content_models"
require "govuk_content_models/require_all"

module ContentApiArtefactExtensions
  extend ActiveSupport::Concern

  included do
    attr_accessor :edition, :licence, :places, :assets, :country, :extra_related_artefacts, :group
    scope :live, where(state: 'live')
  end

  def live_tagged_related_artefacts
    groups = related_artefacts_grouped_by_distance(related_artefacts.live)

    artefacts = groups.map do |key, artefacts|
      artefacts.each {|a| a.group = key }
    end.flatten

    artefacts += @extra_related_artefacts.to_a if @extra_related_artefacts
    artefacts.uniq(&:slug)
  end

end

class Artefact
  include ContentApiArtefactExtensions
end
