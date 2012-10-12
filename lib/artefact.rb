require "govuk_content_models"
require "govuk_content_models/require_all"

module ContentApiArtefactExtensions
  extend ActiveSupport::Concern

  included do
    attr_accessor :edition, :licence
    field :description, type: String
    scope :live, where(state: 'live')
  end

  def live_related_artefacts
    related_artefacts.live
  end
end

class Artefact
  include ContentApiArtefactExtensions
end