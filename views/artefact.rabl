object false

node :_response_info do
  { status: "ok" }
end

glue @artefact do
  extends "_full_artefact", object: @artefact
end

child @artefact.tags => :tags do
  extends "_tag"
end

child @artefact.live_related_artefacts => :related do
  extends "_basic_artefact"
end
