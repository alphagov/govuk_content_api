require 'test_helper'
require 'link_header'
require 'uri'

class TagTypeRequestTest < GovUkContentApiTest

  describe "/tag_types.json" do
    it "should display a list of tag types" do
      get "/tag_types.json"

      response = JSON.parse(last_response.body)
      response["results"].each do |result|
        assert result["id"]
        assert result["type"]
      end
    end

    it "should link to the tag type URL" do
      get "/tag_types.json"

      response = JSON.parse(last_response.body)
      section_type = response["results"].find { |t| t["type"] == "section" }
      assert_equal "http://example.org/tags.json?type=section", section_type["id"]
    end

    it "should include the number of tags of each type" do
      mock_tag_types = TagTypes.new(%w(sections keywords))
      app.any_instance.stubs(:known_tag_types).returns(mock_tag_types)
      Tag.expects(:where).with(tag_type: "section").returns(stub(count: 3))
      Tag.expects(:where).with(tag_type: "keyword").returns(stub(count: 0))

      get "/tag_types.json"

      response = JSON.parse(last_response.body)
      section_type = response["results"].find { |t| t["type"] == "section" }
      assert_equal 3, section_type["total"]
      keyword_type = response["results"].find { |t| t["type"] == "keyword" }
      assert_equal 0, keyword_type["total"]
    end
  end
end
