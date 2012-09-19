require 'test_helper'
require 'uri'

class ArtefactRequestTest < GovUkContentApiTest
  def assert_status_field(expected, response)
    assert_equal expected, JSON.parse(response.body)["_response_info"]["status"]
  end

  it "should return 404 if artefact not found" do
    get '/bad-artefact.json'
    assert last_response.not_found?
    assert_status_field "not found", last_response
  end

  it "should return 404 if artefact in draft" do
    artefact = FactoryGirl.create(:non_publisher_artefact, state: 'draft')
    get "/#{artefact.slug}.json"
    assert last_response.not_found?
    assert_status_field "not found", last_response
  end

  it "should return 410 if artefact archived" do
    artefact = FactoryGirl.create(:non_publisher_artefact, state: 'archived')
    get "/#{artefact.slug}.json"
    assert_equal 410, last_response.status
    assert_status_field "gone", last_response
  end

  it "should return related artefacts" do
    related_artefacts = [
      FactoryGirl.create(:artefact, slug: "related-artefact-1", name: "Pies", state: 'live'),
      FactoryGirl.create(:artefact, slug: "related-artefact-2", name: "Cake", state: 'live')
    ]

    artefact = FactoryGirl.create(:non_publisher_artefact, related_artefacts: related_artefacts, state: 'live')

    get "/#{artefact.slug}.json"
    parsed_response = JSON.parse(last_response.body)

    assert_equal 200, last_response.status

    assert_status_field "ok", last_response
    assert_equal 2, parsed_response["related"].length

    related_artefacts.zip(parsed_response["related"]).each do |response_artefact, related_info|
      assert_equal response_artefact.name, related_info["title"]
      artefact_path = "/#{CGI.escape(response_artefact.slug)}.json"
      assert_equal artefact_path, URI.parse(related_info["id"]).path
      assert_equal "http://www.test.gov.uk/#{response_artefact.slug}", related_info["web_url"]
    end
  end

  it "should exclude unpublished related artefacts" do
    related_artefacts = [
      draft    = FactoryGirl.create(:artefact, state: 'draft'),
      live     = FactoryGirl.create(:artefact, state: 'live'),
      archived = FactoryGirl.create(:artefact, state: 'archived')
    ]

    artefact = FactoryGirl.create(:non_publisher_artefact, related_artefacts: related_artefacts, 
        state: 'live', slug: "workaround")

    get "/#{artefact.slug}.json"
    parsed_response = JSON.parse(last_response.body)

    assert_equal 200, last_response.status

    assert_status_field "ok", last_response
    assert_equal 1, parsed_response["related"].length

    assert_equal "http://example.org/#{live.slug}.json", parsed_response['related'][0]["id"]
  end

  it "should return an empty list if there are no related artefacts" do
    artefact = FactoryGirl.create(:non_publisher_artefact, related_artefacts: [], state: 'live')

    get "/#{artefact.slug}.json"
    parsed_response = JSON.parse(last_response.body)

    assert_equal 200, last_response.status

    assert_status_field "ok", last_response
    assert_equal [], parsed_response["related"]
  end

  it "should not look for edition if publisher not owner" do
    artefact = FactoryGirl.create(:non_publisher_artefact, state: 'live')
    
    get "/#{artefact.slug}.json"

    assert_equal 200, last_response.status
    assert_status_field "ok", last_response
    refute JSON.parse(last_response.body)["details"].has_key?('overview')
  end

  it "should give an empty list of tags when there are no tags" do
    artefact = FactoryGirl.create(:non_publisher_artefact, state: 'live')

    get "/#{artefact.slug}.json"

    assert_equal 200, last_response.status
    assert_status_field "ok", last_response
    assert_equal [], JSON.parse(last_response.body)["tags"]
  end

  it "should list section information" do
    sections = [
      ["crime-and-justice", "Crime and justice"],
      ["crime-and-justice/batman", "Batman"]
    ]
    sections.each do |tag_id, title|
      TagRepository.put(tag_id: tag_id, title: title, tag_type: "section")
    end
    artefact = FactoryGirl.create(:non_publisher_artefact, 
        sections: sections.map { |slug, title| slug },
        state: 'live')

    get "/#{artefact.slug}.json"

    assert_equal 200, last_response.status
    assert_status_field "ok", last_response
    parsed_artefact = JSON.parse(last_response.body)
    assert_equal 2, parsed_artefact["tags"].length

    # Note that this will check the ordering too
    sections.zip(parsed_artefact["tags"]).each do |section, tag_info|
      assert_equal section[1], tag_info["title"]
      tag_path = "/tags/#{CGI.escape(section[0])}.json"
      assert_equal tag_path, URI.parse(tag_info["id"]).path
      assert_equal nil, tag_info["web_url"]
      assert_equal "section", tag_info["details"]["type"]
      # Temporary hack until the browse pages are rebuilt
      expected_section_slug = section[0].sub(%r{/}, '#/')
      assert_equal "http://www.test.gov.uk/browse/#{expected_section_slug}", tag_info["content_with_tag"]["web_url"]
    end
  end

  it "should set the format field at the top-level from the artefact" do
    artefact = FactoryGirl.create(:non_publisher_artefact, state: 'live')
    get "/#{artefact.slug}.json"

    assert_equal 200, last_response.status
    response = JSON.parse(last_response.body)
    assert_equal 'smart-answer', response["format"]
  end

  describe "publisher artefacts" do
    it "should return 404 if artefact is publication but never published" do
      edition = FactoryGirl.create(:edition)

      get "/#{edition.artefact.slug}.json"

      assert last_response.not_found?
      assert_status_field "not found", last_response
    end

    it "should return 410 if artefact is publication but only archived" do
      artefact = FactoryGirl.create(:artefact, state: 'live')
      edition = FactoryGirl.create(:edition, state: 'archived', panopticon_id: artefact.id)

      get "/#{edition.artefact.slug}.json"

      assert_equal 410, last_response.status
      assert_status_field "gone", last_response
    end

    it "should return publication data if published" do
      artefact = FactoryGirl.create(:artefact, business_proposition: true, need_id: 1234, state: 'live')
      edition = FactoryGirl.create(:edition, panopticon_id: artefact.id, body: '# Important information', state: 'published')

      get "/#{artefact.slug}.json"
      parsed_response = JSON.parse(last_response.body)

      assert_equal 200, last_response.status

      assert_status_field "ok", last_response
      assert_equal "http://example.org/#{artefact.slug}.json", parsed_response["id"]
      assert_equal "http://www.test.gov.uk/#{artefact.slug}", parsed_response["web_url"]
      assert_equal "<h1>Important information</h1>\n", parsed_response["details"]["body"]
      assert_equal "1234", parsed_response["details"]["need_id"]
      # Temporarily included for legacy GA support. Will be replaced with "proposition" Tags
      assert_equal true, parsed_response["details"]["business_proposition"]
    end

    it "should convert artefact body and part bodies to html" do
      artefact = FactoryGirl.create(:artefact, slug: "annoying", state: 'live')
      edition = FactoryGirl.create(:guide_edition, 
          panopticon_id: artefact.id, 
          parts: [ 
            Part.new(title: "Part One", body: "## Header 2", slug: "part-one")
          ], 
          state: 'published')

      get "/#{artefact.slug}.json"

      parsed_response = JSON.parse(last_response.body)
      assert_equal 200, last_response.status
      assert_equal "<h2>Header 2</h2>\n", parsed_response["details"]["parts"][0]["body"]
    end

    it "should return govspeak in artefact body and part bodies if requested" do
      artefact = FactoryGirl.create(:artefact, slug: "annoying", state: 'live')
      edition = FactoryGirl.create(:guide_edition, 
          panopticon_id: artefact.id, 
          parts: [ 
            Part.new(title: "Part One", body: "## Header 2", slug: "part-one")
          ], 
          state: 'published')

      get "/#{artefact.slug}.json?content_format=govspeak"

      parsed_response = JSON.parse(last_response.body)
      assert_equal 200, last_response.status
      assert_equal "## Header 2", parsed_response["details"]["parts"][0]["body"]
    end

    it "should return parts" do
      artefact = FactoryGirl.create(:artefact, state: 'live')
      edition = FactoryGirl.create(:guide_edition, 
        panopticon_id: artefact.id, 
        parts: [
          Part.new(title: "Part One", order: 1, body: "## Header 2", slug: "part-one") 
        ],
        state: 'published')

      get "/#{artefact.slug}.json"

      parsed_response = JSON.parse(last_response.body)
      assert_equal 200, last_response.status
      expected_first_part = {
        "web_url" => "http://www.test.gov.uk/#{artefact.slug}/part-one",
        "slug" => "part-one",
        "order" => 1,
        "title" => "Part One",
        "body" => "<h2>Header 2</h2>\n"
      }
      assert_equal expected_first_part, parsed_response["details"]["parts"][0]
    end
  end
end
