object false

node :_response_info do
  { status: "ok" }
end

node(:total) { @results.count }

node(:results) do
  @results.map { |r|
    partial "_basic_artefact", object: r
  }
end
