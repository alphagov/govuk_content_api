fields = {
	tag_ids: @artefact.tag_ids,
	:overview => @artefact.edition.overview,
  :alternative_title => @artefact.edition.alternative_title
}
if @artefact.edition.is_a?(AnswerEdition)
    fields[:body] = Govspeak::Document.new(@artefact.edition.body, auto_ids: false).to_html
elsif @artefact.edition.is_a?(GuideEdition) || @artefact.edition.is_a?(BusinessSupportEdition)
    fields[:parts] = partial("parts", :object => @artefact)
end

return fields