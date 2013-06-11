require 'gds_api/fact_cave'

module ContentFormatHelpers

  EMBEDDED_FACT_REGEXP = /\[Fact\:([\w-]+)\]/

  def process_content(string)
    unless params[:content_format] == "govspeak"
      string = Govspeak::Document.new(string, auto_ids: false).to_html
    end
    interpolate_fact_values(string)
  end

private

  def interpolate_fact_values(string)
    string.gsub(EMBEDDED_FACT_REGEXP) do |match|
      if fact = fact_cave.fact($1)
        fact.details.value
      else
        ''
      end
    end
  end

  def fact_cave
    GdsApi::FactCave.new(Plek.current.find('fact-cave'))
  end
end
