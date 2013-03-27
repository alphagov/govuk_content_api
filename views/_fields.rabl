node(:need_id) { |artefact| artefact.need_id }
node(:business_proposition) { |artefact| artefact.business_proposition }
node(:description) { |artefact| artefact.description }
node(:language) { |artefact| artefact.language }
node(:need_extended_font) { |artefact| artefact.need_extended_font }

[:body, :alternative_title, :more_information, :min_value, :max_value,
    :short_description, :introduction, :will_continue_on, :continuation_link, :link, :alternate_methods,
    :video_summary, :video_url, :licence_identifier, :licence_short_description, :licence_overview,
    :lgsl_code, :lgil_override, :minutes_to_complete, :place_type,
    :eligibility, :evaluation, :additional_information,
    :business_support_identifier, :max_employees, :organiser, :summary, :alert_status,
    :change_description].each do |field|
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
  if artefact.places.first && artefact.places.first["error"]
    [
      { error: artefact.places.first["error"] }
    ]
  else
    artefact.places.map do |place|
      [:name, :address1, :address2, :town, :postcode, 
          :email, :phone, :text_phone, :fax, 
          :access_notes, :general_notes, :url,
          :location].each_with_object({}) do |field_name, hash|
        hash[field_name.to_s] = place[field_name.to_s]
      end
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

node(nil, :if => lambda { |artefact| artefact.assets }) do |artefact|
  artefact.assets.each_with_object({}) do |(key, details), assets|
    assets[key] = {
      "web_url" => details["file_url"],
      "content_type" => details["content_type"],
    }
  end
end

node(:country, :if => lambda { |artefact| artefact.country.is_a?(Country) }) do |artefact|
  {
    "name" => artefact.country.name,
    "slug" => artefact.country.slug,
  }
end

node(:countries, :if => lambda { |artefact| @countries and artefact.slug == 'foreign-travel-advice' }) do |artefact|
  @countries.map do |c|
    {
      :id => country_url(c),
      :name => c.name,
      :identifier => c.slug,
      :web_url => country_web_url(c),
      :updated_at => (c.edition.published_at || c.edition.updated_at).iso8601,
      :change_description => c.edition.change_description
    }
  end
end
