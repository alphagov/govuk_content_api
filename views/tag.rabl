object false

node :_response_info do
  { status: "ok" }
end

glue @tag do
  node(:id) { tag_url(@tag) }
  node(:web_url) { tag_web_url(@tag) }
  attribute :title
  node :details do
    {
      type: @tag.tag_type,
      description: @tag.description,
      
    }
  end
  node :parent do
    if @tag.parent
      { 
        id: tag_url(@tag.parent), 
        web_url: tag_web_url(@tag.parent),
        title: @tag.parent.title 
      }
    else
      nil
    end
  end
end
