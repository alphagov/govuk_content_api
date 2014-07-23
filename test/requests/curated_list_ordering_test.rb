require 'test_helper'

class CuratedListOrderingTest < GovUkContentApiTest

  def setup
    super

    @tag = FactoryGirl.create(
      :live_tag,
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
        title: artefact.name,
        panopticon_id: artefact.id,
        state: "published",
        slug: artefact.slug
      )
    }

    FactoryGirl.create(
      :live_tag,
      tag_id: "x-men",
      title: "X-Men",
      tag_type: "section"
    )

    @other_section_artefact = FactoryGirl.create(
      :artefact,
      owning_app: "publisher",
      sections: ["x-men"],
      name: "James Howlett",
      slug: "james-howlett",
      state: "live"
    )
    @other_section_guide = FactoryGirl.create(
      :guide_edition,
      panopticon_id: @other_section_artefact.id,
      state: "published",
      slug: @other_section_artefact.slug
    )
  end

  def result_titles
    assert last_response.ok?
    results = JSON.parse(last_response.body)["results"]
    results.map { |r| r["title"] }
  end

  def assert_result_titles(expected_titles, options = {})
    if options.fetch(:check_order, true)
      assert_equal expected_titles, result_titles
    else
      assert_equal expected_titles.sort, result_titles.sort
    end
  end

  it "should return a curated list of results" do
    curated_list = FactoryGirl.create(:curated_list)
    curated_list.sections = [@tag.tag_id]
    curated_list.artefact_ids = [
      @live_artefacts[2]._id,
      @live_artefacts[0]._id,
      @live_artefacts[1]._id
    ]
    curated_list.save!

    get "/with_tag.json?section=batman&sort=curated"

    assert_result_titles ["Bat 3", "Bat", "Bat 2"]
  end

  it "should include unlisted items at the end" do
    curated_list = FactoryGirl.create(
      :curated_list,
      sections: [@tag.tag_id],
      artefact_ids: [@live_artefacts[2], @live_artefacts[1]].map(&:_id)
    )

    get "/with_tag.json?section=batman&sort=curated"
    assert_result_titles ["Bat 3", "Bat 2", "Bat"]
  end

  it "should include unlisted items in name order" do
    curated_list = FactoryGirl.create(
      :curated_list,
      sections: [@tag.tag_id],
      artefact_ids: [@live_artefacts[2]._id]
    )

    get "/with_tag.json?section=batman&sort=curated"
    assert_result_titles ["Bat 3", "Bat", "Bat 2"]
  end

  it "should sort mixed case artefact titles indifferently" do
    artefacts = [
      ["superman", "Superman"],
      ["lex-luthor", "lex luthor"],
      ["bizarro", "bizarro"]
    ]

    FactoryGirl.create(:live_tag, tag_id: "superman", title: "Superman", tag_type: "section")
    artefacts.each { |slug, name|
      FactoryGirl.create(
        :artefact,
        owning_app: "custom-application",
        section_ids: ["superman"],
        name: name,
        slug: slug,
        state: "live"
      )
    }
    get "/with_tag.json?section=superman&sort=curated"

    assert_result_titles ["bizarro", "lex luthor", "Superman"]
  end

  it "should exclude items not in the section" do
    curated_list = FactoryGirl.create(
      :curated_list,
      sections: [@tag.tag_id],
      artefact_ids: [@live_artefacts[1]._id, @other_section_artefact._id]
    )
    get "/with_tag.json?section=batman&sort=curated"
    assert_result_titles ["Bat", "Bat 2", "Bat 3"], check_order: false
    assert_equal "Bat 2", result_titles[0]
  end

  it "should return all live things if no curated list is found" do
    get "/with_tag.json?section=batman&sort=curated"

    assert_result_titles ["Bat", "Bat 2", "Bat 3"], check_order: false
  end

  it "should return all live things if the list is empty" do
    curated_list = FactoryGirl.create(:curated_list, sections: [@tag.tag_id])
    get "/with_tag.json?section=batman&sort=curated"
    assert_result_titles ["Bat", "Bat 2", "Bat 3"], check_order: false
  end
end
