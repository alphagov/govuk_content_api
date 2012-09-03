object false

node :_response_info do
  { status: "ok" }
end

node(:description) { "Tags!" }
node(:total) { @tags.count }
node(:startIndex) { 1 }
node(:pageSize) { @tags.count }
node(:currentPage) { 1 }
node(:pages) { 1 }
node(:results) do
  @tags.map { |r|
    parent = { id: tag_url(r.parent), title: r.title } if r.parent
    {
      id: tag_url(r),
      title: r.title,
      details: {
        type: r.tag_type,
        description: r.description,
        parent: parent
      }
    }
  }
end
