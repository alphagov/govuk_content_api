class TagTypePresenter
  def initialize(tag_type, url_helper)
    @tag_type = tag_type
    @url_helper = url_helper
  end

  def present
    {
      id: @url_helper.tag_type_url(@tag_type),
      type: @tag_type.singular,
      total: Tag.where(tag_type: @tag_type.singular).count
    }
  end
end
