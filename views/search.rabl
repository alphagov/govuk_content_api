object false

node :_response_info do
  { status: "ok" }
end

node(:total) { @results.count }
node(:startIndex) { 1 }
node(:pageSize) { @results.count }
node(:currentPage) { 1 }
node(:pages) { 1 }

node(:results) do
  @results.map { |r|
    {
      id: r.link,
      title: r.title,
      details: {
        description: r.description,
        additional_links: (r.additional_links || []).map { |al|
          {
            title: al.title,
            url: al.link
          }
        }
      }
    }
  }
end
