object false
node(:status) { "ok" }
node(:description) { "Items with tag" }
node(:total) { "tbd" }
node(:startIndex) { 1 }
node(:pageSize) { "tbd" }
node(:currentPage) { 1 }
node(:pages) { 1 }

node :result do
  {
    id: @tag.tag_id,
    title: @tag.title,
    fields: {
      type: @tag.tag_type,
      description: @tag.description,
      parent: 'tbd' #@tag.parent_id
    }
  }
end
