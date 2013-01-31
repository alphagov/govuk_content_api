object false

node :_response_info do
  { status: "ok" }
end

node(:total) { @countries.count }

node(:results) do
  @countries.map do |c|
    base_attributes = {
      :id => country_url(c),
      :name => c.name,
      :identifier => c.slug,
      :web_url => country_web_url(c)
    }
    base_attributes.merge!({
      :alert_status => c.edition.alert_status,
      :updated_at => c.edition.updated_at
    }) if c.edition
    base_attributes
  end
end
