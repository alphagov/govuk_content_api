object false
node :response do
  basic = {
    status: 'ok',
    total: 1,
    result: {
      id: @artefact.slug,
      title: @artefact.name,
      tag_ids: @artefact.tag_ids,
      fields: {}
    }
  }

  basic[:result][:fields] = partial("fields", :object => @artefact)

  basic
end
