object false

node :_response_info do
  { status: "ok" }
end

node(:total) { @artefacts.count }
node(:results) do
  @artefacts.map do |a|
    {
      :id => artefact_url(a),
      :web_url => artefact_web_url(a),
      :title => a.name,
      :format => a.kind,
    }
  end
end
