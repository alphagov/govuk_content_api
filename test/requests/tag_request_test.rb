require 'test_helper'

class TagRequestTest < GovUkContentApiTest

  describe "/tags/:tag_type/:tag_id.json" do
    it "should load a specific tag" do
      fake_tag = Tag.new(
        tag_id: "good-tag", tag_type: "section",
        description: "Lots to say for myself", name: "Good tag"
      )
      Tag.expects(:by_tag_id).with("good-tag", "section").returns(fake_tag)

      get "/tags/sections/good-tag.json"
      assert last_response.ok?
      assert_status_field "ok", last_response
      response = JSON.parse(last_response.body)
      assert_equal "Lots to say for myself", response["details"]["description"]
      assert_equal "http://example.org/tags/sections/good-tag.json", response["id"]
      assert_equal nil, response["web_url"]
      assert_equal(
        "#{public_web_url}/browse/good-tag",
        response["content_with_tag"]["web_url"]
      )
    end

    it "should return 404 if specific tag not found" do
      Tag.expects(:by_tag_id).with("bad-tag", "section").returns(nil)
      get "/tags/sections/bad-tag.json"
      assert last_response.not_found?
      assert_status_field "not found", last_response
    end

    it "should have full URI in ID field" do
      tag = FactoryGirl.create(:tag, tag_id: "crime", tag_type: "section")
      get "/tags/sections/crime.json"
      full_url = "http://example.org/tags/sections/crime.json"
      found_id = JSON.parse(last_response.body)['id']
      assert_equal full_url, found_id
    end

    it "should be able to fetch tag over SSL" do
      tag = FactoryGirl.create(:tag, tag_id: 'crime')
      get "https://example.org/tags/sections/crime.json"
      full_url = "https://example.org/tags/sections/crime.json"
      found_id = JSON.parse(last_response.body)['id']
      assert_equal full_url, found_id
    end

    it "should include nil for the parent tag" do
      tag = FactoryGirl.create(:tag, tag_id: 'crime')
      get "/tags/sections/crime.json"
      response = JSON.parse(last_response.body)
      assert_includes response.keys, 'parent'
      assert_equal nil, response['parent']
    end

    it "should load a tag that includes a slash" do
      FactoryGirl.create(:tag, tag_id: 'crime/batman')

      get "/tags/sections/crime%2Fbatman.json"
      assert last_response.ok?
      assert_status_field "ok", last_response
      assert_equal(
        "http://example.org/tags/sections/crime%2Fbatman.json",
        JSON.parse(last_response.body)["id"]
      )
    end

    it "should link to the correct browse URL for a subsection tag" do
      # This is a temporary thing until the browse pages have been rebuilt to have proper URL's
      FactoryGirl.create(:tag, tag_id: 'crime/batman', tag_type: 'section')
      get "/tags/sections/crime%2Fbatman.json"

      assert last_response.ok?
      response = JSON.parse(last_response.body)
      assert_equal "#{public_web_url}/browse/crime/batman", response["content_with_tag"]["web_url"]
    end

    describe "has a parent tag" do
      before do
        @parent = FactoryGirl.create(:tag, tag_id: 'crime-and-prison')
      end

      it "should include the parent tag" do
        tag = FactoryGirl.create(:tag, tag_id: 'crime', parent_id: @parent.tag_id)
        get "/tags/sections/crime.json"
        response = JSON.parse(last_response.body)
        expected = {
          "id" => "http://example.org/tags/sections/crime-and-prison.json",
          "web_url" => nil,
          "details"=>{
            "description" => nil,
            "short_description" => nil,
            "type" => "section"
          },
          "content_with_tag" => {
            "id" => "http://example.org/with_tag.json?section=crime-and-prison",
            "web_url" => "#{public_web_url}/browse/crime-and-prison"
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
