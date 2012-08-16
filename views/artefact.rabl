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
    basic[:result][:fields][:body] = Govspeak::Document.new(@artefact.edition.body, auto_ids: false).to_html
    basic[:result][:fields][:alternative_title] = @artefact.edition.alternative_title
  elsif @artefact.edition.is_a?(GuideEdition)
    basic[:result][:fields][:overview] = @artefact.edition.overview
    basic[:result][:fields][:body] = Govspeak::Document.new(@artefact.edition.whole_body, auto_ids: false).to_html
    basic[:result][:fields][:alternative_title] = @artefact.edition.alternative_title
    node :parts do
      partial("parts", :object => @artefact)
    end
  end

  basic
end

