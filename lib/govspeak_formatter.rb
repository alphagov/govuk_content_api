class GovspeakFormatter

  EMBEDDED_FACT_REGEXP = /\[fact\:([a-z0-9-]+)\]/i # e.g. [fact:vat-rates]

  def initialize(format, fact_cave_api, options = {})
    unless [:html, :govspeak].include? format
      raise ArgumentError.new("Invalid format #{format}")
    end

    @format = format
    @fact_cave_api = fact_cave_api
    @auto_ids = options.fetch(:auto_ids, false)
  end

  def format(govspeak_string)
    if @format == :html
      formatted = Govspeak::Document.new(govspeak_string, auto_ids: @auto_ids).to_html
    else
      formatted = govspeak_string
    end

    interpolate_fact_values(formatted)
  end

private
  def interpolate_fact_values(string)
    string.gsub(EMBEDDED_FACT_REGEXP) do |match|
      if fact = @fact_cave_api.fact($1)
        fact.details.formatted_value
      else
        ''
      end
    end
  end
end
