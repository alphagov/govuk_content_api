require "presenters/basic_artefact_presenter"
require "presenters/tag_presenter"
require "presenters/artefact_part_presenter"
require "presenters/artefact_licence_presenter"
require "presenters/local_authority_presenter"

class ArtefactPresenter

  BASE_FIELDS = %w(
    need_id business_proposition description language need_extended_font
  ).map(&:to_sym)

  OPTIONAL_FIELDS = %w(
    additional_information
    alert_status
    alternate_methods
    alternative_title
    body
    business_support_identifier
    change_description
    continuation_link
    eligibility
    evaluation
    introduction
    lgil_override
    lgsl_code
    licence_identifier
    licence_overview
    licence_short_description
    link
    max_employees
    max_value
    min_value
    minutes_to_complete
    more_information
    organiser
    place_type
    reviewed_at
    short_description
    summary
    video_summary
    video_url
    will_continue_on
  ).map(&:to_sym)

  def initialize(artefact, url_helper, govspeak_formatter)
    @artefact = artefact
    @url_helper = url_helper
    @govspeak_formatter = govspeak_formatter
  end

  def present_with(items, presenter_class)
    items.map do |item|
      presenter_class.new(item, @url_helper).present
    end
  end

  def present
    presented = BasicArtefactPresenter.new(@artefact, @url_helper).present

    presented["tags"] = present_with(@artefact.combined_tags, TagPresenter)
    presented["related"] = present_with(
      @artefact.live_tagged_related_artefacts,
      BasicArtefactPresenter
    )

    # MERGE ALL THE THINGS!
    presented["details"] = [
      base_fields,
      optional_fields,
      parts,
      nodes,
      places,
      licence,
      local_authority,
      local_interaction,
      local_service,
      expectations,
      assets,
      country
    ].inject(&:merge)

    presented["related_external_links"] = @artefact.external_links.map do |l|
      {
        "title" => l.title,
        "url" => l.url
      }
    end

    presented
  end

private
  def base_fields
    Hash[BASE_FIELDS.map do |field|
      [field, @artefact.send(field)]
    end]
  end

  def optional_fields
    fields = OPTIONAL_FIELDS.select { |f| @artefact.edition.respond_to?(f) }
    Hash[fields.map do |field|
      field_value = @artefact.edition.send(field)

      if @artefact.edition.class::GOVSPEAK_FIELDS.include?(field)
        [field, @govspeak_formatter.format(field_value)]
      else
        [field, field_value]
      end
    end]
  end

  def parts
    return {} unless @artefact.edition.respond_to?(:order_parts)

    presented_parts = @artefact.edition.order_parts.map do |part|
      ArtefactPartPresenter.new(
        @artefact,
        part,
        @url_helper,
        @govspeak_formatter
      ).present
    end

    {"parts" => presented_parts}
  end

  def nodes
    return {} unless @artefact.edition.is_a?(SimpleSmartAnswerEdition)

    presented_nodes = @artefact.edition.nodes.map do |n|
      {
        "kind" => n.kind,
        "slug" => n.slug,
        "title" => n.title,
        "body" => @govspeak_formatter.format(n.body),
        "options" => n.options.map { |o|
          {
            "label" => o.label,
            "slug" => o.slug,
            "next_node" => o.next_node,
          }
        }
      }
    end

    {"nodes" => presented_nodes}
  end

  def licence
    return {} unless @artefact.licence

    {
      "licence" => ArtefactLicencePresenter.new(@artefact.licence).present
    }
  end

  def places
    return {} unless @artefact.places

    place_list = if @artefact.places.first && @artefact.places.first["error"]
      [
        { "error" => @artefact.places.first["error"] }
      ]
    else
      @artefact.places.map do |place|
        [:name, :address1, :address2, :town, :postcode,
            :email, :phone, :text_phone, :fax,
            :access_notes, :general_notes, :url,
            :location].each_with_object({}) do |field_name, hash|
          hash[field_name.to_s] = place[field_name.to_s]
        end
      end
    end

    { "places" => place_list }
  end

  def local_authority
    return {} unless @artefact.local_authority

    presenter = LocalAuthorityPresenter.new(
      @artefact.local_authority,
      @url_helper
    )
    { "local_authority" => presenter.present }
  end

  def local_interaction
    return {} unless @artefact.local_interaction

    {
      "local_interaction" => {
        "lgsl_code" => @artefact.local_interaction.lgsl_code,
        "lgil_code" => @artefact.local_interaction.lgil_code,
        "url" => @artefact.local_interaction.url
      }
    }
  end

  def local_service
    return {} unless @artefact.edition.respond_to?(:service)

    {
      "local_service" => {
        "description" => @artefact.edition.service.description,
        "lgsl_code" => @artefact.edition.service.lgsl_code,
        "providing_tier" => @artefact.edition.service.providing_tier
      }
    }
  end

  def expectations
    return {} unless @artefact.edition.respond_to?(:expectations)

    {
      "expectations" => @artefact.edition.expectations.map(&:text) 
    }
  end

  def assets
    return {} unless @artefact.assets

    @artefact.assets.each_with_object({}) do |(key, details), assets|
      assets[key] = {
        "web_url" => details["file_url"],
        "content_type" => details["content_type"],
      }
    end
  end

  def country
    return {} unless @artefact.country.is_a?(Country)

    {
      "country" => {
        "name" => @artefact.country.name,
        "slug" => @artefact.country.slug
      }
    }
  end
end
