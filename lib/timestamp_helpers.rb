module TimestampHelpers
  def most_recent_updated_at(artefact)
    updated_options = [artefact.updated_at]
    updated_options << artefact.edition.updated_at if artefact.edition
    updated_options.compact.max
  end
end