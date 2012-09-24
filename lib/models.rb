require "govuk_content_models"
require "govuk_content_models/require_all"

class Artefact
  attr_accessor :edition, :licence
  field :description, type: String

  scope :live, where(state: 'live')

  def live_related_artefacts
    related_artefacts.live
  end
end