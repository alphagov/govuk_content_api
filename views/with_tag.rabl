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
        id: r.slug,
        title: r.name,
        fields: {
	  tags: r.tag_ids
        }
      }
    }
  }
end

