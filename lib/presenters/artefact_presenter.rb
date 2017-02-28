require "presenters/basic_artefact_presenter"
require "presenters/artefact_part_presenter"

# Full presenter for artefacts.
#
# This presenter handles all relevant fields for the various different types of
# artefact, so it's pretty expensive and so we only use this for a single
# artefact's view (the `*.json` handler in `govuk_content_api.rb`).
class ArtefactPresenter

  BASE_FIELDS = %w(
    need_ids description language
  ).map(&:to_sym)

  OPTIONAL_FIELDS = %w(
    additional_information
    alert_status
    alternate_methods
    body
    start_button_text
    change_description
    continuation_link
    department_analytics_profile
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
    more_information
    need_to_know
    organiser
    place_type
    presentation_toggles
    reviewed_at
    short_description
    summary
    video_summary
    video_url
    will_continue_on
  ).map(&:to_sym)

  def initialize(artefact, url_helper, govspeak_formatter, options = {})
    @artefact = artefact
    @url_helper = url_helper
    @govspeak_formatter = govspeak_formatter
    @options = options
  end

  def edition
    @artefact.edition
  end

  def present_with(items, presenter_class)
    items.map do |item|
      presenter_class.new(item, @url_helper).present
    end
  end

  def present
    presented = BasicArtefactPresenter.new(@artefact, @url_helper).present

    # MERGE ALL THE THINGS!
    presented["details"] = [
      base_fields,
      optional_fields,
      parts,
      nodes,
      assets,
      country,
      organisation,
      downtime,
    ].inject(&:merge)

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

      if @artefact.edition.class.const_defined?(:GOVSPEAK_FIELDS) && @artefact.edition.class::GOVSPEAK_FIELDS.include?(field)
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

  def organisation
    return {} unless @artefact.edition.is_a?(CampaignEdition)

    {
      "organisation" => {
        "formatted_name" => @artefact.edition.organisation_formatted_name,
        "url" => @artefact.edition.organisation_url,
        "brand_colour" => @artefact.edition.organisation_brand_colour,
        "crest" => @artefact.edition.organisation_crest,
      }
    }
  end

  def downtime
    downtime = Downtime.for(@artefact)
    return {} if downtime.nil? || !downtime.publicise?

    {
      "downtime" => {
        "message" => downtime.message,
      }
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
