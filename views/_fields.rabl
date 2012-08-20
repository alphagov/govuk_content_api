fields = {
	tag_ids: @artefact.tag_ids,
	:overview => @artefact.edition.overview,
  :alternative_title => @artefact.edition.alternative_title
}

if @artefact.edition.respond_to?(:body)
  fields[:body] = Govspeak::Document.new(@artefact.edition.body, auto_ids: false).to_html
end

if @artefact.edition.respond_to?(:parts)
  fields[:parts] = partial("parts", :object => @artefact)
end

if @artefact.edition.respond_to?(:more_information)
  attributes :more_information
end

if @artefact.edition.is_a?(BusinessSupportEdition)
  attributes :min_value, :max_value, :short_description
end

if @artefact.edition.is_a?(TransactionEdition)
  attributes :introduction, :will_continue_on, :link, :more_information, :alternate_methods
end

if @artefact.edition.respond_to?(:video_summary)
  attributes :video_summary, :video_url
end

if @artefact.edition.respond_to?(:licence_overview)
  attributes :licence_short_description, :licence_overview
end

if @artefact.edition.respond_to?(:lgsl_code)
  attributes :lgsl_code, :lgil_override, :introduction, :more_information
end

if @artefact.edition.respond_to?(:minutes_to_complete)
  attributes :minutes_to_complete, :expectation_ids
end

if @artefact.edition.respond_to?(:place_type)
  attributes :introduction, :place_type, :expectation_ids
end

return fields