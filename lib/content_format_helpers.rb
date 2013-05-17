require "data_api"

module ContentFormatHelpers
  EMBEDDED_DATA_API_REGEXP = /\[DataApi\:([0-9a-fA-F]{24})\]/

  def format_content(string, format = nil)
    return string if format == "govspeak"
    string = render_embedded_data(string)
    Govspeak::Document.new(string, auto_ids: false).to_html
  end

  def render_embedded_data(govspeak)
    return govspeak if govspeak.blank?
    govspeak.gsub(ContentFormatHelpers::EMBEDDED_DATA_API_REGEXP) do
      if value = DataApi.find_by_id($1)
        value
      else
        ''
      end
    end
  end
end
