module ContentFormatHelpers
  def format_content(string, format = nil)
    return string if format == "govspeak"
    Govspeak::Document.new(string, auto_ids: false).to_html
  end
end
