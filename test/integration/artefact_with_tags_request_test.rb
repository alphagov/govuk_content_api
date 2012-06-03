require 'test_helper'

class ArtefactWithTagsRequestTest < GovUkContentApiTest
  def test_it_returns_404_if_tag_not_found
    Tag.expects(:where).with(tag_id: 'farmers').returns([])

    get "/with_tag.json?tag=farmers"

    assert last_response.not_found?
    assert_equal 'not found', JSON.parse(last_response.body)["response"]["status"]
  end

  def test_it_returns_an_array_of_results
    t = Tag.new(tag_id: 'farmers', name: 'Farmers', tag_type: 'Audience')
    Tag.stubs(:where).with(tag_id: 'farmers').returns([t])

    smart_answer = Artefact.new(owning_app: 'smart-answers')
    Artefact.expects(:any_in).with(tag_ids: ['farmers']).returns([smart_answer])

    get "/with_tag.json?tag=farmers"

    assert last_response.ok?
    assert_equal 1, JSON.parse(last_response.body)["response"]["results"].count
  end

  def test_it_allows_filtering_by_multiple_tags
    farmers = Tag.new(tag_id: 'farmers', name: 'Farmers', tag_type: 'Audience')
    business = Tag.new(tag_id: 'business', name: 'Business', tag_type: 'Audience')

    Tag.stubs(:where).with(tag_id: 'farmers').returns([farmers])
    Tag.expects(:where).with(tag_id: 'business').returns([business])

    smart_answer = Artefact.new(owning_app: 'smart-answers')
    Artefact.expects(:any_in).with(tag_ids: ['farmers', 'business']).returns([smart_answer])

    get "/with_tag.json?tag=farmers,business"
    assert last_response.ok?
    assert_equal 1, JSON.parse(last_response.body)["response"]["results"].count
  end
end
