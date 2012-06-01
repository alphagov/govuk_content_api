object false
node :response do
  {
    status: 'ok',
    total: 1,
    result: {
        id: @artefact.slug,
        title: @artefact.name,
        fields: {
          tags: @artefact.tag_ids
        }
    }
  }
end

