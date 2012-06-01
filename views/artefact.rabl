object false
node :response do
  basic = {
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

  if @artefact.edition.is_a?(AnswerEdition)
    basic[:result][:fields][:overview] = @artefact.edition.overview
    basic[:result][:fields][:body] = @artefact.edition.body
    basic[:result][:fields][:alternative_title] = @artefact.edition.alternative_title
  end

  basic
end

