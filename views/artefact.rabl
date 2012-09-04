object false

node :_response_info do
  { status: "ok" }
end

glue @artefact do
  extends "_artefact", object: @artefact
end
