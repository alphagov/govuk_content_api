require 'test_helper'

class CuratedListOrderingTest < GovUkContentApiTest

  def setup
    super

    @tag = FactoryGirl.create(
      :tag,
      tag_id: "batman",
      title: "Batman",
      tag_type: "section"
    )

    bat_data = [
      ["batman", "Bat"],
      ["batman-returns", "Bat 2"],
      ["batman-forever", "Bat 3"]
    ]
    @live_artefacts = bat_data.map { |slug, name|
      FactoryGirl.create(
        :artefact,
        owning_app: "publisher",
        sections: ["batman"],
        name: name,
        slug: slug,
        state: "live"
      )
    }

    joker_data = [
      ["joker", "Joker"],
      ["harley-quinn", "Harley Quinn"]
    ]

    @draft_artefacts = joker_data.map { |slug, name|
      FactoryGirl.create(
        :artefact,
        owning_app: "publisher",
        sections: ["batman"],
        name: name,
        slug: slug,
        state: "draft"
      )
    }

    @guides = @live_artefacts.map { |artefact|
      FactoryGirl.create(
        :guide_edition,
        panopticon_id: artefact.id,
        state: "published",
        slug: artefact.slug
      )
    }
  end

  it "should return a curated list of results" do
    curated_list = FactoryGirl.create(:curated_list)
    curated_list.sections = [@tag.tag_id]
    curated_list.artefact_ids = [@live_artefacts[2]._id, @live_artefacts[0]._id]
    curated_list.save!

    get "/with_tag.json?tag=batman&sort=curated"

    assert last_response.ok?
    assert_equal 2, JSON.parse(last_response.body)["results"].count
    assert_equal "Bat 3", JSON.parse(last_response.body)["results"][0]["title"]
    assert_equal "Bat", JSON.parse(last_response.body)["results"][1]["title"]
  end

  it "should return all live things if no curated list is found" do
    get "/with_tag.json?tag=batman&sort=curated"

    assert last_response.ok?
    results = JSON.parse(last_response.body)["results"]
    assert_equal ["Bat", "Bat 2", "Bat 3"], results.map { |r| r["title"] }.sort
  end
end
