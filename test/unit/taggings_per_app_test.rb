require "test_helper"

describe TaggingsPerApp do
  describe "#taggings" do
    it "returns the tags in a useful format" do
      FactoryGirl.create(:live_artefact, owning_app: 'publisher')
      artefact = FactoryGirl.create(:live_artefact, owning_app: 'smartanswers', content_id: '26e3bd4d-c0e8-4256-b417-6488f356ab89')

      tag = FactoryGirl.create(:live_tag, tag_type: "section", tag_id: "a-tag-id", content_id: "03aded93-677f-4061-8024-d4a4c55b2fea")
      artefact.set_tags_of_type("section", ["a-tag-id"])
      artefact.save

      taggings = TaggingsPerApp.new('smartanswers').taggings

      assert_equal({
        "26e3bd4d-c0e8-4256-b417-6488f356ab89" => {
          "mainstream_browse_pages" => ["03aded93-677f-4061-8024-d4a4c55b2fea"],
          "parent" => ["03aded93-677f-4061-8024-d4a4c55b2fea"]
        }
      }, taggings)
    end
  end
end
