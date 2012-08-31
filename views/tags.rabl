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
      {
        id: "#{@base_url}/tags/#{escape(r.tag_id)}.json",
        title: r.title,
        details: {
          type: r.tag_type,
          description: 'tbd', #r.description,
          parent: 'tbd' #r.parent_id
        }
      }
    }
end
