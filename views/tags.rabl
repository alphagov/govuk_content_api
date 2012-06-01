object false
node :response do
  {
    status: 'ok',
    description: "Tags!",
    total: @tags.count,
    startIndex: 1,
    pageSize: @tags.count,
    currentPage: 1,
    pages: 1,
    results: @tags.map { |r|
      {
        id: r.tag_id,
        title: r.title,
        fields: {
	  type: r.tag_type,
	  description: 'tbd', #r.description,
	  parent: 'tbd' #r.parent_id
        }
      }
    }
  }
end

