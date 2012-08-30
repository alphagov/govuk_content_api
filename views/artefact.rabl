object false

node :_response_info do
  { status: "ok" }
end

glue @artefact do
  attribute :slug => :id
  attribute :name => :title
  attribute :tag_ids
  node(:related_artefact_ids){ @artefact.related_artefacts.map(&:slug) }
  node(:fields) { partial("fields", object: @artefact) }
end
