provider = @artefact.edition.service.preferred_provider(params[:snac_code])
interaction = provider.preferred_interaction_for(@artefact.edition.lgsl_code, @artefact.edition.lgil_override)

node do
  {
    name: provider.name,
    snac: provider.snac,
    tier: provider.tier,
    contact_address: provider.contact_address,
    contact_url: provider.contact_url,
    contact_phone: provider.contact_phone,
    contact_email: provider.contact_email,
    interaction: {
      lgsl_code: interaction.lgsl_code,
      lgil_code: interaction.lgil_code,
      url: interaction.url
    }
  }
end