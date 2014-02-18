require_relative '../test_helper'

class GroupedArtefactsRequestTest < GovUkContentApiTest

  describe "requests for tagged artefacts grouped by format" do
    before(:each) do
      @tag = FactoryGirl.create(:tag, tag_id: 'business', title: 'Business', tag_type: 'section')
      @artefacts = [
        # Services
        FactoryGirl.create_list(:live_artefact_with_edition, 2, kind: "answer", section_ids: [@tag.tag_id]),
        FactoryGirl.create_list(:live_artefact_with_edition, 2, kind: "guide", section_ids: [@tag.tag_id]),
        # Guidance
        FactoryGirl.create_list(:whitehall_live_artefact, 2, kind: "detailed_guide", section_ids: [@tag.tag_id]),
        FactoryGirl.create_list(:whitehall_live_artefact, 1, kind: "guidance", section_ids: [@tag.tag_id]),
        # Forms
        FactoryGirl.create_list(:whitehall_live_artefact, 2, kind: "form", section_ids: [@tag.tag_id]),
        # Document collections
        FactoryGirl.create_list(:whitehall_live_artefact, 3, kind: "research", section_ids: [@tag.tag_id]),
      ]
    end

    it "returns the results in groups" do
      get "/with_tag.json?section=business&group_by=format"

      assert last_response.ok?
      response = JSON.parse(last_response.body)
      groups = response["grouped_results"]

      assert_equal 4, groups.size

      assert_equal "Services", groups[0]["name"]
      assert_equal ["answer", "answer", "guide", "guide"], groups[0]["items"].map {|h| h["format"] }.sort

      assert_equal "Guidance", groups[1]["name"]
      assert_equal ["detailed_guide", "detailed_guide", "guidance"], groups[1]["items"].map {|h| h["format"] }.sort

      assert_equal "Forms", groups[2]["name"]
      assert_equal ["form", "form"], groups[2]["items"].map {|h| h["format"] }

      assert_equal "Research and analysis", groups[3]["name"]
      assert_equal ["research", "research", "research"], groups[3]["items"].map {|h| h["format"] }
    end
  end

end
