node(:need_id) { |artefact| artefact.need_id }
node(:business_proposition) { |artefact| artefact.business_proposition }

[:alternative_title, :min_value, :max_value, :will_continue_on, 
    :continuation_link, :link, :alternate_methods, :video_url,
    :video_summary, :licence_identifier,  :lgsl_code, :lgil_override,
    :minutes_to_complete, :place_type, :business_support_identifier, :max_employees,
    :organiser, :contact_details].each do |field|
  node(field, :if => lambda { |artefact| artefact.edition.respond_to?(field) }) do |artefact|
    artefact.edition.send(field)
  end
end

[:body, :overview, :more_information, :short_description, :introduction,
    :licence_short_description, :licence_overview, :eligibility, :evaluation, 
    :additional_information].each do |govspeak_field|
  node(govspeak_field, :if => lambda { |artefact| artefact.edition.respond_to?(govspeak_field) }) do |artefact|
    format_content(artefact.edition.send(govspeak_field))
  end
end

node(:parts, :if => lambda { |artefact| artefact.edition.respond_to?(:order_parts) }) do |artefact|
  partial("parts", object: artefact)
end

node(:licence, :if => lambda { |artefact| artefact.licence }) do |artefact|
  partial("licence", object: artefact)
end

node(:local_authority, :if => lambda { |artefact| artefact.edition.is_a?(LocalTransactionEdition) && params[:snac] }) do |artefact|
  provider = artefact.edition.service.preferred_provider(params[:snac])
  partial("_local_authority", object: provider)
end

node(:local_interaction, :if => lambda { |artefact| artefact.edition.is_a?(LocalTransactionEdition) && params[:snac] }) do |artefact|
  provider = artefact.edition.service.preferred_provider(params[:snac])
  if provider
    interaction = provider.preferred_interaction_for(artefact.edition.lgsl_code, artefact.edition.lgil_override)
    partial("_local_interaction", object: interaction)
  end
end

node(:local_service, :if => lambda { |artefact| artefact.edition.respond_to?(:service) }) do |artefact|
  partial("local_service", object: artefact.edition.service)
end

node(:expectations, :if => lambda { |artefact| artefact.edition.respond_to?(:expectations) }) do |artefact|
  artefact.edition.expectations.map(&:text)
end
