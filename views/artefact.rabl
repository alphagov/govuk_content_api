object false

node :_response_info do
  { status: "ok" }
end

glue @artefact do
  extends "_basic_artefact"
end

child @artefact => :details do
  extends "_fields"
end

child @artefact.tags => :tags do
  extends "_tag"
end

child @artefact.live_tagged_related_artefacts => :related do
  extends "_basic_artefact"
end

node(:related_external_links) do
  @artefact.external_links.map do |link|
    {
      :title => link.title,
      :url => link.url,
    }
  end
end
