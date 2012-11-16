object false

node :_response_info do
  { status: "ok" }
end

node(:total) { @results.count }

node(:results) do
  @results.map do |r|
    {
      :id => artefact_url(r),
      :web_url => artefact_web_url(r),
      :identifier => r.edition.business_support_identifier,
      :title => r.edition.title,
      :short_description => r.edition.short_description,
      :format => r.kind 
    }
  end
end
