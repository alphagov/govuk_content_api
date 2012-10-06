object false

node :_response_info do
  { status: "ok" }
end

node(:description) { "Licences" }
node(:total) { @licences.count }
node(:results) do
  @licences.map { |licence|
    partial "_full_artefact", object: licence
  }
end
