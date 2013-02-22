node(:id) { |artefact| artefact_url(artefact) }
node(:web_url) { |artefact| artefact_web_url(artefact) }
node(:title) do |artefact|
  if artefact.edition and artefact.edition.respond_to?(:title)
    artefact.edition.title
  else
    artefact.name
  end
end
node(:format) do |artefact|
  if artefact.edition and artefact.edition.respond_to?(:format)
    artefact.edition.format.underscore
  else
    artefact.kind
  end
end

node(:updated_at) { |artefact|
  presented_updated_date(artefact).iso8601
}
