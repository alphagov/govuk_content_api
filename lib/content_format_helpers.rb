module ContentFormatHelpers
  def format_content(string)
    if params[:content_format] == "govspeak"
      return string
    end
    Govspeak::Document.new(string, auto_ids: false).to_html
  end
end