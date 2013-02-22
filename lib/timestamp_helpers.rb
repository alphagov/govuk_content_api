module TimestampHelpers

  # Returns the updated date that should be presented to the user
  def presented_updated_date(artefact)
    if artefact.kind == 'travel-advice'
      # For travel_advice there's an explicit public publish date.
      # (Fallback to updated_at if it's missing - either previewing a draft, or old data)
      artefact.edition.published_at || artefact.edition.updated_at
    else
      # For everythign else, the latest updated_at of the artefact or edition
      updated_options = [artefact.updated_at]
      updated_options << artefact.edition.updated_at if artefact.edition
      updated_options.compact.max
    end
  end
end
