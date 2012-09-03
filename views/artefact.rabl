object false

node :_response_info do
  { status: "ok" }
end

glue @artefact do
  attribute :slug => :id
  attribute :name => :title
  node(:details) { partial("fields", object: @artefact) }
  if @artefact.edition
    node(:format) { @artefact.edition.format }
  end
  # Explicit naming here gives us an empty list if there are no tags
  child :tags => :tags do
    node(:id) { |tag| tag_url(tag) }
    attribute :tag_type => :type
    attribute :title
  end
  child :related_artefacts => :related_artefacts do
    node(:id) { |a| artefact_url(a) }
    attribute :name => :title
  end
end
