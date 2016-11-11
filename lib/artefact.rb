require "govuk_content_models"
require "govuk_content_models/require_all"

module ContentApiArtefactExtensions
  extend ActiveSupport::Concern

  included do
    attr_accessor(
      :edition,
      :licence,
      :assets,
      :country,
      :group,
    )
    scope :live, -> { where(state: 'live') }
  end
end

class Artefact
  include ContentApiArtefactExtensions
end
