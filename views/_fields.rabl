node(:need_id) { |artefact| artefact.need_id }
node(:business_proposition) { |artefact| artefact.business_proposition }

[:format, :alternative_title, :overview, :more_information, :min_value, :max_value, 
    :short_description, :introduction, :will_continue_on, :link, :alternate_methods, 
    :video_summary, :video_url, :licence_identifier, :licence_short_description, :licence_overview,
    :lgsl_code, :lgil_override, :minutes_to_complete, :expectation_ids, :place_type].each do |field|
  node(field, :if => lambda { |artefact| artefact.edition.respond_to?(field) }) do |artefact| 
    artefact.edition.send(field)
  end
end

node(:body, :if => lambda { |artefact| artefact.edition.respond_to?(:body) }) do |artefact| 
  format_content(artefact.edition.body)
end

node(:parts, :if => lambda { |artefact| artefact.edition.respond_to?(:parts) }) do |artefact|
  partial("parts", object: artefact)
end
