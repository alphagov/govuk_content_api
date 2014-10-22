class GovspeakFormatter

  def initialize(format, options = {})
    unless [:html, :govspeak].include? format
      raise ArgumentError.new("Invalid format #{format}")
    end

    @format = format
    @auto_ids = options.fetch(:auto_ids, false)
  end

  def format(govspeak_string)
    if @format == :html
      Govspeak::Document.new(govspeak_string, auto_ids: @auto_ids).to_html
    else
      govspeak_string
    end
  end
end
