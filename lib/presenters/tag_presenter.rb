class TagPresenter

  def initialize(tag, url_helper)
    @tag = tag
    @url_helper = url_helper
  end

  def present
    presented = {
      "id" => @url_helper.tag_url(@tag),
      "web_url" => nil,
      "title" => @tag.title,
      "details" => {
        "description" => @tag.description,
        "short_description" => @tag.short_description,
        "type" => @tag.tag_type
      },
      "content_with_tag" => {
        "id" => @url_helper.with_tag_url(@tag),
        "web_url" => @url_helper.with_tag_web_url(@tag)
      }
    }

    if @tag.parent
      presented["parent"] = TagPresenter.new(@tag.parent, @url_helper).present
    end

    presented
  end
end
