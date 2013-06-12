
# This has an implicit requirement on GdsApi::Helpers being included.
# The App includes them before this class.
module ContentFormatHelpers

  EMBEDDED_FACT_REGEXP = /\[fact\:([a-z0-9-]+)\]/i # e.g. [fact:vat-rates]

  def process_content(string)
    unless params[:content_format] == "govspeak"
      string = Govspeak::Document.new(string, auto_ids: false).to_html
    end
    interpolate_fact_values(string)
  end

private

  def interpolate_fact_values(string)
    string.gsub(EMBEDDED_FACT_REGEXP) do |match|
      if fact = fact_cave_api.fact($1)
        fact.details.value
      else
        ''
      end
    end
  end
end
