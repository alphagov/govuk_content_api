object false

node :_response_info do
  { status: "ok" }
end

node(:total) { @countries.count }

node(:results) do
  @countries.map do |c|
    {
      :id => country_url(c),
      :name => c.name,
      :identifier => c.slug,
      :web_url => country_web_url(c),
      :alert_status => c.alert_status
    }
  end
end
