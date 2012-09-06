object false

node :_response_info do
  { status: "ok" }
end

glue @artefact do
  extends "_full_artefact", object: @artefact
end
