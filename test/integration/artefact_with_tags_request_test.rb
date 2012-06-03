require 'test_helper'

class ArtefactWithTagsRequestTest < GovUkContentApiTest
  def test_it_returns_404_if_tag_not_found
    Tag.stubs(:where).with(tag_id: 'farmers').returns([])

    get "/with_tag.json?tag=farmers"

    assert last_response.not_found?
    assert_equal 'not found', JSON.parse(last_response.body)["response"]["status"]
  end
end
