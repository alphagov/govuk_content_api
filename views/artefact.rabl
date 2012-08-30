object false
node(:status) { "ok" }
node :result do
  {
    id: @artefact.slug,
    title: @artefact.name,
    tag_ids: @artefact.tag_ids,
    related_artefact_ids: @artefact.related_artefacts.map(&:slug),
    fields: partial("fields", object: @artefact)
  }
end
