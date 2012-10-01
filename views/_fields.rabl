node(:need_id) { |artefact| artefact.need_id }
node(:business_proposition) { |artefact| artefact.business_proposition }

[:format, :alternative_title, :overview, :more_information, :min_value, :max_value,
    :short_description, :introduction, :will_continue_on, :continuation_link, :link, :alternate_methods,
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

node(:licence, :if => lambda { |artefact| artefact.licence }) do |artefact|
  partial("licence", object: artefact)
end

node(:local_authority, :if => lambda { |artefact| artefact.edition.is_a?(LocalTransactionEdition) && params[:snac_code] }) do |artefact|
  provider = artefact.edition.service.preferred_provider(params[:snac_code])
  partial("_local_authority", object: provider)
end

node(:local_interaction, :if => lambda { |artefact| artefact.edition.is_a?(LocalTransactionEdition) && params[:snac_code] }) do |artefact|
  provider = artefact.edition.service.preferred_provider(params[:snac_code])
  if provider
    interaction = provider.preferred_interaction_for(artefact.edition.lgsl_code, artefact.edition.lgil_override)
    partial("_local_interaction", object: interaction)
  end
end

node(:local_service, :if => lambda { |artefact| artefact.edition.respond_to?(:service) }) do |artefact|
  partial("local_service", object: artefact.edition.service)
end