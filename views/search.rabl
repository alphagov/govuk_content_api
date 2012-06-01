object false
node :response do
  {
    status: 'ok',
    description: "Search for your query",
    total: @results.count,
    startIndex: 1,
    pageSize: @results.count,
    currentPage: 1,
    pages: 1,
    results: @results.map { |r|
      {
        id: r.link,
        title: r.title,
        fields: {
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
  }
end

