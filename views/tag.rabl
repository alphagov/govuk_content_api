object false
node :response do
  {
    status: 'ok',
    description: "Items with tag",
    total: 'tbd', #@tags.count,
    startIndex: 1,
    pageSize: 'tbd', #@tags.count,
    currentPage: 1,
    pages: 1,
    result: {
      id: "#{@base_url}/tags/#{escape(@tag.tag_id)}.json",
      title: @tag.title,
      fields: {
        type: @tag.tag_type,
        description: @tag.description,
        parent: 'tbd' #@tag.parent_id
      }
    }
  }
end

