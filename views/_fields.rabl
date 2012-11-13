node(:need_id) { |artefact| artefact.need_id }
node(:business_proposition) { |artefact| artefact.business_proposition }
node(:description) { |artefact| artefact.description }

[:body, :alternative_title, :more_information, :min_value, :max_value,
    :short_description, :introduction, :will_continue_on, :continuation_link, :link, :alternate_methods,
    :video_summary, :video_url, :licence_identifier, :licence_short_description, :licence_overview,
    :lgsl_code, :lgil_override, :minutes_to_complete, :place_type,
    :eligibility, :evaluation, :additional_information,
    :business_support_identifier, :max_employees, :organiser, :contact_details].each do |field|
  node(field, :if => lambda { |artefact| artefact.edition.respond_to?(field) }) do |artefact|
    if artefact.edition.class::GOVSPEAK_FIELDS.include?(field)
      format_content(artefact.edition.send(field))
    else
      artefact.edition.send(field)
    end
  end
end

node(:parts, :if => lambda { |artefact| artefact.edition.respond_to?(:order_parts) }) do |artefact|
  partial("parts", object: artefact)
end

node(:licence, :if => lambda { |artefact| artefact.licence }) do |artefact|
  partial("licence", object: artefact)
end

node(:places, :if => lambda { |artefact| artefact.places }) do |artefact|
  artefact.places.map do |place|
    [:name, :address1, :address2, :town, :postcode, 
        :email, :phone, :text_phone, :fax, 
        :access_notes, :general_notes, :url,
        :location].each_with_object({}) do |field_name, hash|
      hash[field_name.to_s] = place[field_name.to_s]
    end
  end
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
