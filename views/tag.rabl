object false

node :_response_info do
  { status: "ok" }
end

glue @tag do
  node(:id) { tag_url(@tag) }
  attribute :title
  node :details do
    parent = { id: tag_url(@tag.parent), title: @tag.parent.title } if @tag.parent
    {
      type: @tag.tag_type,
      description: @tag.description,
      parent: parent
    }
  end
end
