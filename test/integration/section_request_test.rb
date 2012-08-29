require 'test_helper'

class SectionRequestTest < GovUkContentApiTest
  should "load list of sections" do
    tag1 = FactoryGirl.create(:tag, tag_id: 'crime', tag_type: 'section')
    tag2 = FactoryGirl.create(:tag, tag_id: 'crime/batman', tag_type: 'section')
    tag3 = FactoryGirl.create(:tag, tag_id: 'batman', tag_type: 'audience')

    get "/sections.json"
    assert last_response.ok?
    assert_equal 'ok', JSON.parse(last_response.body)["response"]["status"]
    assert_equal 2, JSON.parse(last_response.body)['response']['results'].count
  end
end
