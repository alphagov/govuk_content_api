require 'test_helper'

class SectionRequestTest < GovUkContentApiTest
  should "load list of sections" do
    tag1 = FactoryGirl.create(:tag, tag_id: 'crime', tag_type: 'section')
    tag2 = FactoryGirl.create(:tag, tag_id: 'crime/batman', tag_type: 'section')
    tag3 = FactoryGirl.create(:tag, tag_id: 'batman', tag_type: 'audience')

    get "/sections.json"
    assert last_response.ok?
    assert_status_field "ok", last_response
    assert_equal 2, JSON.parse(last_response.body)['results'].count
  end

  should "load a section" do
    tag1 = FactoryGirl.create(:tag, tag_id: 'batman', tag_type: 'section')

    get "/sections/batman.json"
    assert last_response.ok?
    assert_status_field "ok", last_response
    assert_equal 'http://contentapi.test.gov.uk/tags/batman.json', JSON.parse(last_response.body)['id']
  end

  should "load a section that includes a slash" do
    tag1 = FactoryGirl.create(:tag, tag_id: 'crime', tag_type: 'section')
    tag2 = FactoryGirl.create(:tag, tag_id: 'crime/batman', tag_type: 'section')

    get "/sections/crime%2Fbatman.json"
    assert last_response.ok?
    assert_status_field "ok", last_response
    assert_equal 'http://contentapi.test.gov.uk/tags/crime%2Fbatman.json', JSON.parse(last_response.body)['id']
  end

end
