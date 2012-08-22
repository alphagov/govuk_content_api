fields = {
	tag_ids: @artefact.tag_ids,
}

[:section, :alternative_title, :overview, :more_information, :min_value, :max_value, :short_description, :introduction, :will_continue_on, :link, :more_information, :alternate_methods, :video_summary, :video_url, :licence_short_description, :licence_overview, :lgsl_code, :lgil_override, :more_information, :minutes_to_complete, :expectation_ids, :place_type].each do |field|
  if @artefact.edition.respond_to?(field)
    fields[field] = @artefact.edition.send(field)
  end
end

if @artefact.edition.respond_to?(:body)
  fields[:body] = @artefact.edition.body
end

if @artefact.edition.respond_to?(:parts)
  fields[:parts] = partial("parts", :object => @artefact)
end

return fields