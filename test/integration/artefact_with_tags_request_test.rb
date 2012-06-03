require 'test_helper'

class ArtefactWithTagsRequestTest < GovUkContentApiTest
  def test_it_returns_404_if_tag_not_found
    Tag.expects(:where).with(tag_id: 'farmers').returns([])

    get "/with_tag.json?tag=farmers"

    assert last_response.not_found?
    assert_equal 'not found', JSON.parse(last_response.body)["response"]["status"]
  end

  def test_it_returns_the_standard_response_even_if_zero_results
    t = Tag.new(tag_id: 'farmers', name: 'Farmers', tag_type: 'Audience')
    Tag.stubs(:where).with(tag_id: 'farmers').returns([t])

    Artefact.expects(:any_in).with(tag_ids: ['farmers']).returns([])

    get "/with_tag.json?tag=farmers"
    parsed_response = JSON.parse(last_response.body)

    assert last_response.ok?
    assert_equal 'ok', parsed_response["response"]["status"]
    assert_equal 0, parsed_response["response"]["total"]
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

  def test_it_excludes_unpublished_publisher_items
    t = Tag.new(tag_id: 'farmers', name: 'Farmers', tag_type: 'Audience')
    Tag.stubs(:where).with(tag_id: 'farmers').returns([t])

    answer = Artefact.new(owning_app: 'publisher', slug: 'fake')
    real_answer = Artefact.new(owning_app: 'publisher', slug: 'real')
    Edition.expects(:where).with(slug: 'fake', state: 'published').returns([])
    Edition.expects(:where).with(slug: 'real', state: 'published').returns([AnswerEdition.new])

    smart_answer = Artefact.new(owning_app: 'smart-answers')
    Artefact.expects(:any_in).with(tag_ids: ['farmers']).returns([answer, smart_answer, real_answer])

    get "/with_tag.json?tag=farmers"

    assert last_response.ok?, "request failed: #{last_response.status}"
    assert_equal 2, JSON.parse(last_response.body)["response"]["results"].count
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
