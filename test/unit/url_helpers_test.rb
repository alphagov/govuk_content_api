require "test_helper"
require "url_helpers"

class URLHelpersTest < MiniTest::Spec

  include URLHelpers

  def url(path)
    # We don't have access to Sinatra's url method, so fake it
    path
  end

  def env
    # Mock out the environment to something with no HTTP_API_PREFIX
    {}
  end

  describe "with_tag URLs" do

    DummyTag = Struct.new(:tag_id, :tag_type)

    it "works for a single tag" do
      tag = DummyTag.new("crime", "section")
      assert_equal "/with_tag.json?section=crime", with_tag_url(tag)
    end

    it "works for tags of multiple types" do
      tags = [
        DummyTag.new("crime", "section"),
        DummyTag.new("onions", "keyword"),
      ]
      assert_equal(
        "/with_tag.json?keyword=onions&section=crime",
        with_tag_url(tags)
      )
    end

    it "doesn't support multiple tags of the same type" do
      # Well, not yet, at least
      tags = [
        DummyTag.new("crime", "section"),
        DummyTag.new("batman", "section"),
      ]
      assert_raises ArgumentError do with_tag_url(tags) end
    end

    it "accepts parameters" do
      tag = DummyTag.new("crime", "section")
      params = { sort: "curated", include_children: 1 }
      assert_equal(
        "/with_tag.json?section=crime&include_children=1&sort=curated",
        with_tag_url(tag, params)
      )
    end
  end
end

