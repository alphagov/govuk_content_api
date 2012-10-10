require 'test_helper'

class ArtefactWithTagsRequestTest < GovUkContentApiTest
  it "should return 404 if tag not found" do
    Tag.expects(:where).with(tag_id: 'farmers').returns([])

    get "/with_tag.json?tag=farmers"

    assert last_response.not_found?
    assert_status_field "not found", last_response
  end

  it "should return the standard response even if zero results" do
    t = Tag.new(tag_id: 'farmers', name: 'Farmers', tag_type: 'Audience')
    Tag.stubs(:where).with(tag_id: 'farmers').returns([t])

    get "/with_tag.json?tag=farmers"
    parsed_response = JSON.parse(last_response.body)

    assert last_response.ok?
    assert_status_field "ok", last_response
    assert_equal 0, parsed_response["total"]
  end

  it "should return an array of results" do
    farmers = FactoryGirl.create(:tag, tag_id: 'farmers', title: 'Farmers', tag_type: 'section')
    FactoryGirl.create(:artefact, owning_app: "smart-answers", sections: ['farmers'], state: 'live')

    get "/with_tag.json?tag=farmers"

    assert last_response.ok?
    assert_equal 1, JSON.parse(last_response.body)["results"].count
  end

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

  it "should return a 404 if an unsupported sort order is requested" do
    batman = FactoryGirl.create(:tag, tag_id: 'batman', title: 'Batman', tag_type: 'section')
    bat = FactoryGirl.create(:artefact, owning_app: 'publisher', sections: ['batman'], name: 'Bat', slug: 'batman')
    bat_guide = FactoryGirl.create(:guide_edition, panopticon_id: bat.id, state: "published", slug: 'batman')
    get "/with_tag.json?tag=batman&sort=bobbles"

    assert last_response.not_found?
    assert_status_field "not found", last_response
  end

  it "should exclude artefacts which aren't live" do
    FactoryGirl.create(:tag, tag_id: 'farmers')
    draft    = FactoryGirl.create(:non_publisher_artefact, sections: ['farmers'], state: 'draft')
    live     = FactoryGirl.create(:non_publisher_artefact, sections: ['farmers'], state: 'live')
    archived = FactoryGirl.create(:non_publisher_artefact, sections: ['farmers'], state: 'archived')

    get "/with_tag.json?tag=farmers"

    assert last_response.ok?
    response = JSON.parse(last_response.body)
    assert_equal 1, response["results"].count
    assert_equal "http://example.org/#{live.slug}.json", response["results"][0]["id"]
  end

  it "should exclude unpublished publisher items" do
    farmers = FactoryGirl.create(:tag, tag_id: 'farmers', title: 'Farmers', tag_type: 'section')
    business = FactoryGirl.create(:tag, tag_id: 'business', title: 'Business', tag_type: 'section')
    artefact = FactoryGirl.create(:artefact, owning_app: "publisher", sections: ['farmers', 'business'])
    FactoryGirl.create(:edition, panopticon_id: artefact.id, state: "ready")

    get "/with_tag.json?tag=farmers"

    assert last_response.ok?, "request failed: #{last_response.status}"
    assert_equal 0, JSON.parse(last_response.body)["results"].count
  end

  it "should allow filtering by multiple tags" do
    farmers = FactoryGirl.create(:tag, tag_id: 'farmers', title: 'Farmers', tag_type: 'section')
    business = FactoryGirl.create(:tag, tag_id: 'business', title: 'Business', tag_type: 'section')
    FactoryGirl.create(:artefact, owning_app: "smart-answers", sections: ['farmers', 'business'], state: 'live')

    get "/with_tag.json?tag=farmers,business"
    assert last_response.ok?
    assert_equal 1, JSON.parse(last_response.body)["results"].count
  end

  it "should return include children in array of results" do
    FactoryGirl.create(:tag, tag_id: 'business', title: 'Business', tag_type: 'section')
    FactoryGirl.create(:tag, tag_id: 'foo', title: 'Business', tag_type: 'section', parent_id: "business")
    FactoryGirl.create(:artefact, owning_app: "smart-answers", sections: ['business'], state: 'live')
    FactoryGirl.create(:artefact, owning_app: "smart-answers", sections: ['foo'], state: 'live')

    get "/with_tag.json?tag=business&include_children=1"

    assert last_response.ok?
    assert_equal 2, JSON.parse(last_response.body)["results"].count
  end

  it "should return 501 if more than 1 child requested" do
    get "/with_tag.json?tag=business&include_children=2"

    assert_equal 501, last_response.status
  end
end
