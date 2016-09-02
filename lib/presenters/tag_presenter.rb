class TagPresenter

  def initialize(tag, url_helper)
    @tag = tag
    @url_helper = url_helper
  end

  def present
    presented = {
      "id" => @url_helper.tag_url(@tag),
      "content_id" => @tag.content_id,
      "slug" => @tag.tag_id,
      "web_url" => @url_helper.tag_web_url(@tag),
      "title" => @tag.title,
      "details" => {
        "description" => @tag.description,
        "short_description" => @tag.short_description,
        "type" => @tag.tag_type
      },
      "content_with_tag" => {
        "web_url" => @url_helper.tagged_content_web_url(@tag)
      },
      "state" => @tag.state,
    }

    if @tag.parent
      presented["parent"] = TagPresenter.new(@tag.parent, @url_helper).present
    else
      presented["parent"] = nil
    end

    presented
  end
end
