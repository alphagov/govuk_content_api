require 'test_helper'

class TagListRequestTest < GovUkContentApiTest
  describe "/tags.json" do
    it "should load list of tags" do
      Tag.expects(:all).returns([
        Tag.new(tag_id: 'good-tag', tag_type: 'Section', description: 'Lots to say for myself', name: 'good tag'),
        Tag.new(tag_id: 'better-tag', tag_type: 'Audience', description: 'Lots to say', name: 'better tag'),
      ])
      get "/tags.json"
      assert last_response.ok?
      assert_status_field "ok", last_response
      assert_equal 2, JSON.parse(last_response.body)['results'].count
    end

    it "should filter all tags by type" do
      Tag.expects(:where).with("tag_type" => 'Section').returns([
        Tag.new(tag_id: 'good-tag', tag_type: 'Section', description: 'Lots to say for myself', name: 'good tag'),
      ])
      get "/tags.json?type=Section"
      assert last_response.ok?
      assert_status_field "ok", last_response
      assert_equal 1, JSON.parse(last_response.body)['results'].count
    end

    it "should have full uri in id field in index action" do
      tag = FactoryGirl.create(:tag, tag_id: 'crime')
      get "/tags.json"
      expected_id = "http://example.org/tags/crime.json"
      expected_url = "http://www.test.gov.uk/browse/crime"
      assert_equal expected_id, JSON.parse(last_response.body)['results'][0]['id']
      assert_equal nil, JSON.parse(last_response.body)['results'][0]['web_url']
      assert_equal expected_url, JSON.parse(last_response.body)['results'][0]["content_with_tag"]["web_url"]
    end

    it "provides a public API URL when requested through that route" do
      # We identify public API URLs by the presence of an HTTP_API_PREFIX
      # environment variable, set by the internal proxy
      tag = FactoryGirl.create(:tag, tag_id: 'crime')
      get '/tags.json', {}, {'HTTP_API_PREFIX' => 'api'}

      expected_id = "http://www.test.gov.uk/api/tags/crime.json"
      assert_equal expected_id, JSON.parse(last_response.body)['results'][0]['id']
    end
  end
end
