node(:id) { |artefact| artefact_url(artefact) }
node(:web_url) { |artefact| artefact_web_url(artefact) }
node(:title) do |artefact|
  if artefact.edition
    artefact.edition.title
  else
    artefact.name
  end
end
node(:format) do |artefact|
  if artefact.edition
    artefact.edition.format.underscore
  else
    artefact.kind
  end
end
node(:language) { |artefact| artefact.language }

node(:updated_at) { |artefact|
  most_recent_updated_at(artefact).iso8601
}
