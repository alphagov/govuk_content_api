require 'test_helper'

class CuratedListOrderingTest < GovUkContentApiTest

  it "should return a curated list of results" do
    batman_tag = FactoryGirl.create(
      :tag,
      tag_id: 'batman',
      title: 'Batman',
      tag_type: 'section'
    )

    bat_data = [
      ['batman', 'Bat'],
      ['batman-returns', 'Bat 2'],
      ['batman-forever', 'Bat 3']
    ]
    bat_artefacts = bat_data.map { |slug, name|
      FactoryGirl.create(
        :artefact,
        owning_app: 'publisher',
        sections: ['batman'],
        name: name,
        slug: slug
      )
    }

    bat_guides = bat_artefacts.map { |artefact|
      FactoryGirl.create(
        :guide_edition,
        panopticon_id: artefact.id,
        state: "published",
        slug: artefact.slug
      )
    }
    curated_list = FactoryGirl.create(:curated_list)
    curated_list.sections = [batman_tag.tag_id]
    curated_list.artefact_ids = [bat_artefacts[2]._id, bat_artefacts[0]._id]
    curated_list.save!

    get "/with_tag.json?tag=batman&sort=curated"

    assert last_response.ok?
    assert_equal 2, JSON.parse(last_response.body)["results"].count
    assert_equal "Bat 3", JSON.parse(last_response.body)["results"][0]["title"]
    assert_equal "Bat", JSON.parse(last_response.body)["results"][1]["title"]
  end

  it "should return all things if no curated list is found" do
    batman = FactoryGirl.create(:tag, tag_id: 'batman', title: 'Batman', tag_type: 'section')
    bat = FactoryGirl.create(:artefact, owning_app: 'publisher', sections: ['batman'], name: 'Bat', slug: 'batman', state: 'live')
    bat_guide = FactoryGirl.create(:guide_edition, panopticon_id: bat.id, state: "published", slug: 'batman')
    get "/with_tag.json?tag=batman&sort=curated"

    assert last_response.ok?
    assert_equal 1, JSON.parse(last_response.body)["results"].count
  end
end
