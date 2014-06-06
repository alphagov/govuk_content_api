require "test_helper"
require "url_helper"

describe URLHelper do
  DummyTag = Struct.new(:tag_id, :tag_type)
  class MockApp
    def self.url(u)
      u
    end
  end

  it "should use the app's `url` method when there is no prefix" do
    mock_app = mock("app") do
      expects(:url).with("/foobang").returns("http://example.com/foobang")
    end
    helper = URLHelper.new(mock_app, nil, nil)
    assert_equal "http://example.com/foobang", helper.api_url("/foobang")
  end

  it "should use the app's `url` method when the prefix is empty" do
    mock_app = mock("app") do
      expects(:url).with("/foobang").returns("http://example.com/foobang")
    end
    helper = URLHelper.new(mock_app, nil, "")
    assert_equal "http://example.com/foobang", helper.api_url("/foobang")
  end

  it "should use the website root when there is an API prefix" do
    mock_app = mock("app") do
      expects(:uri).never
    end
    helper = URLHelper.new(mock_app, "http://example.com", "api")
    assert_equal "http://example.com/api/foobang", helper.api_url("/foobang")
  end

  it "should produce public web URLs" do
    mock_app = mock("app") do
      expects(:uri).never
    end
    helper = URLHelper.new(mock_app, "http://example.com", nil)
    assert_equal "http://example.com/foobang", helper.public_web_url("/foobang")
  end

  describe "tag URLs" do
    it "builds a url from a tag object" do
      helper = URLHelper.new(MockApp, "http://example.com", nil)
      tag = DummyTag.new("crime", "section")

      assert_equal "/tags/section/crime.json", helper.tag_url(tag)
    end

    it "builds a url from a tag id and tag type" do
      helper = URLHelper.new(MockApp, "http://example.com", nil)

      assert_equal "/tags/section/crime.json", helper.tag_url("section", "crime")
    end
  end

  describe "tag_web_url URLs" do
    it "returns nil if the type isn't in the list" do
      tag = DummyTag.new("rock", "genre")
      helper = URLHelper.new(mock("app"), "http://example.com", nil)

      assert_equal nil, helper.tag_web_url(tag)
    end

    it "returns a /browse URL for a section tag" do
      tag = DummyTag.new("crime", "section")
      helper = URLHelper.new(mock("app"), "http://example.com", nil)

      assert_equal "http://example.com/browse/crime", helper.tag_web_url(tag)
    end

    it "returns a root URL for a specialist_sector tag" do
      tag = DummyTag.new("oil-and-gas", "specialist_sector")
      helper = URLHelper.new(mock("app"), "http://example.com", nil)

      assert_equal "http://example.com/oil-and-gas", helper.tag_web_url(tag)
    end
  end

  describe "tagged_content URLs" do
    it "works for a single tag" do
      helper = URLHelper.new(MockApp, "http://example.com", nil)
      tag = DummyTag.new("crime", "section")
      assert_equal "/with_tag.json?section=crime", helper.tagged_content_url(tag)
    end

    it "works for tags of multiple types" do
      tags = [
        DummyTag.new("crime", "section"),
        DummyTag.new("onions", "keyword"),
      ]
      helper = URLHelper.new(MockApp, "http://example.com", nil)
      assert_equal(
        "/with_tag.json?keyword=onions&section=crime",
        helper.tagged_content_url(tags)
      )
    end

    it "doesn't support multiple tags of the same type" do
      # Well, not yet, at least
      tags = [
        DummyTag.new("crime", "section"),
        DummyTag.new("batman", "section"),
      ]
      helper = URLHelper.new(MockApp, "http://example.com", nil)
      assert_raises ArgumentError do helper.tagged_content_url(tags) end
    end

    it "accepts parameters" do
      tag = DummyTag.new("crime", "section")
      params = { sort: "curated", include_children: 1 }
      helper = URLHelper.new(MockApp, "http://example.com", nil)
      assert_equal(
        "/with_tag.json?section=crime&include_children=1&sort=curated",
        helper.tagged_content_url(tag, params)
      )
    end
  end

  describe "tagged_content_web_url URLs" do
    it "returns nil if the type isn't in the list" do
      tag = DummyTag.new("rock", "genre")
      helper = URLHelper.new(mock("app"), "http://example.com", nil)

      assert_equal nil, helper.tagged_content_web_url(tag)
    end

    it "returns a /browse URL for a section tag" do
      tag = DummyTag.new("crime", "section")
      helper = URLHelper.new(mock("app"), "http://example.com", nil)

      assert_equal "http://example.com/browse/crime", helper.tagged_content_web_url(tag)
    end

    it "returns a root URL for a specialist_sector tag" do
      tag = DummyTag.new("oil-and-gas", "specialist_sector")
      helper = URLHelper.new(mock("app"), "http://example.com", nil)

      assert_equal "http://example.com/oil-and-gas", helper.tagged_content_web_url(tag)
    end
  end
end
