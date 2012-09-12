require 'test_helper'

class TagRequestTest < GovUkContentApiTest

  context "/tags.json" do
    should "load list of tags" do
      Tag.expects(:all).returns([
        Tag.new(tag_id: 'good-tag', tag_type: 'Section', description: 'Lots to say for myself', name: 'good tag'),
        Tag.new(tag_id: 'better-tag', tag_type: 'Audience', description: 'Lots to say', name: 'better tag'),
      ])
      get "/tags.json"
      assert last_response.ok?
      assert_status_field "ok", last_response
      assert_equal 2, JSON.parse(last_response.body)['results'].count
    end

    should "filter all tags by type" do
      Tag.expects(:where).with(tag_type: 'Section').returns([
        Tag.new(tag_id: 'good-tag', tag_type: 'Section', description: 'Lots to say for myself', name: 'good tag'),
      ])
      get "/tags.json?type=Section"
      assert last_response.ok?
      assert_status_field "ok", last_response
      assert_equal 1, JSON.parse(last_response.body)['results'].count
    end

    should "have full uri in id field in index action" do
      tag = FactoryGirl.create(:tag, tag_id: 'crime')
      get "/tags.json"
      expected_id = "http://example.org/tags/crime.json"
      expected_url = "http://example.org/browse/crime"
      assert_equal expected_id, JSON.parse(last_response.body)['results'][0]['id']
      assert_equal nil, JSON.parse(last_response.body)['results'][0]['web_url']
      assert_equal expected_url, JSON.parse(last_response.body)['results'][0]["content_with_tag"]["web_url"]
    end
  end

  context "/tags/:id.json" do
    should "load a specific tag" do
      fake_tag = Tag.new(tag_id: 'good-tag', tag_type: 'Section', description: 'Lots to say for myself', name: 'good tag')
      Tag.expects(:where).with(tag_id: 'good-tag').returns([fake_tag])
      get '/tags/good-tag.json'
      assert last_response.ok?
      assert_status_field "ok", last_response
      response = JSON.parse(last_response.body)
      assert_equal "Lots to say for myself", response["details"]["description"]
      assert_equal "http://example.org/tags/good-tag.json", response["id"]
      assert_equal nil, response["web_url"]
      assert_equal "http://example.org/browse/good-tag", response["content_with_tag"]["web_url"]
    end

    should "return 404 if specific tag not found" do
      Tag.expects(:where).with(tag_id: 'bad-tag').returns([])
      get '/tags/bad-tag.json'
      assert last_response.not_found?
      assert_status_field "not found", last_response
    end

    should "have full uri in id field" do
      tag = FactoryGirl.create(:tag, tag_id: 'crime')
      get "/tags/crime.json"
      full_url = "http://example.org/tags/crime.json"
      found_id = JSON.parse(last_response.body)['id']
      assert_equal full_url, found_id
    end

    should "be able to fetch tag over ssl" do
      tag = FactoryGirl.create(:tag, tag_id: 'crime')
      get "https://example.org/tags/crime.json"
      full_url = "https://example.org/tags/crime.json"
      found_id = JSON.parse(last_response.body)['id']
      assert_equal full_url, found_id
    end

    should "include nil for the parent tag" do
      tag = FactoryGirl.create(:tag, tag_id: 'crime')
      get "/tags/crime.json"
      response = JSON.parse(last_response.body)
      assert_includes response.keys, 'parent'
      assert_equal nil, response['parent']
    end

    should "load a tag that includes a slash" do
      FactoryGirl.create(:tag, tag_id: 'crime/batman')

      get "/tags/crime%2Fbatman.json"
      assert last_response.ok?
      assert_status_field "ok", last_response
      assert_equal 'http://example.org/tags/crime%2Fbatman.json', JSON.parse(last_response.body)['id']
    end

    context "has a parent tag" do
      setup do
        @parent = FactoryGirl.create(:tag, tag_id: 'crime-and-prison')
      end

      should "include the parent tag" do
        tag = FactoryGirl.create(:tag, tag_id: 'crime', parent_id: @parent.tag_id)
        get "/tags/crime.json"
        response = JSON.parse(last_response.body)
        expected = {
          "id" => "http://example.org/tags/crime-and-prison.json",
          "web_url" => nil,
          "details"=>{
            "description" => nil,
            "type" => "section"
          },
          "content_with_tag" => {
            "id" => "http://example.org/with_tag.json?tag=crime-and-prison",
            "web_url" => "http://example.org/browse/crime-and-prison"
          },
          "parent" => nil,
          "title" => @parent.title
        }
        assert_includes response.keys, 'parent'
        assert_equal expected, response['parent']
      end
    end
  end
end
