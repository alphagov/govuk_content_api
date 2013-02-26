require "govuk_content_models"
require "govuk_content_models/require_all"

module ContentApiArtefactExtensions
  extend ActiveSupport::Concern

  included do
    attr_accessor :edition, :licence, :places, :assets, :country
    scope :live, where(state: 'live')
  end

  def live_related_artefacts
    ordered_related_artefacts(related_artefacts.live)
  end
end

class Artefact
  include ContentApiArtefactExtensions
end
