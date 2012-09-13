require 'test_helper'
require 'uri'

class ArtefactRequestTest < GovUkContentApiTest
  def assert_status_field(expected, response)
    assert_equal expected, JSON.parse(response.body)["_response_info"]["status"]
  end

  should "return 404 if artefact not found" do
    Artefact.expects(:where).with(slug: 'bad-artefact').returns([])
    get '/bad-artefact.json'
    assert last_response.not_found?
    assert_status_field "not found", last_response
  end

  should "return 404 if artefact is publication but never published" do
    stub_artefact = Artefact.new(slug: 'unpublished-artefact', owning_app: 'publisher')
    Artefact.stubs(:where).with(slug: 'unpublished-artefact').returns([stub_artefact])
    Edition.stubs(:where).with(slug: 'unpublished-artefact', state: 'published').returns([])
    Edition.stubs(:where).with(slug: 'unpublished-artefact', state: 'archived').returns([])

    get '/unpublished-artefact.json'

    assert last_response.not_found?
    assert_status_field "not found", last_response
  end

  should "return 410 if artefact is publication but only archived" do
    stub_artefact = Artefact.new(slug: 'archived-artefact', owning_app: 'publisher')
    Artefact.stubs(:where).with(slug: 'archived-artefact').returns([stub_artefact])
    Edition.stubs(:where).with(slug: 'archived-artefact', state: 'published').returns([])
    Edition.stubs(:where).with(slug: 'archived-artefact', state: 'archived').returns(['not empty'])

    get '/archived-artefact.json'

    assert_equal 410, last_response.status
    assert_status_field "gone", last_response
  end

  should "return publication data if published" do
    stub_artefact = Artefact.new(slug: 'published-artefact', owning_app: 'publisher', business_proposition: true, need_id: 1234)
    stub_answer = AnswerEdition.new(body: '# Important information')

    Artefact.stubs(:where).with(slug: 'published-artefact').returns([stub_artefact])
    Edition.stubs(:where).with(slug: 'published-artefact', state: 'published').returns([stub_answer])

    get '/published-artefact.json'
    parsed_response = JSON.parse(last_response.body)

    assert last_response.ok?

    assert_status_field "ok", last_response
    assert_equal "http://example.org/#{stub_artefact.slug}.json", parsed_response["id"]
    assert_equal "http://www.test.gov.uk/#{stub_artefact.slug}", parsed_response["web_url"]
    assert_equal "<h1>Important information</h1>\n", parsed_response["details"]["body"]
    assert_equal "1234", parsed_response["details"]["need_id"]
    # Temporarily included for legacy GA support. Will be replaced with "proposition" Tags
    assert_equal true, parsed_response["details"]["business_proposition"]
  end

  should "convert artefact body and part bodies to html" do
    stub_artefact = Artefact.new(slug: 'published-artefact', owning_app: 'publisher')
    stub_answer = GuideEdition.new(body: '# Important information', parts: [Part.new(title: "Part One", body: "## Header 2", slug: "part-one")])

    Artefact.stubs(:where).with(slug: 'published-artefact').returns([stub_artefact])
    Edition.stubs(:where).with(slug: 'published-artefact', state: 'published').returns([stub_answer])

    get '/published-artefact.json'
    parsed_response = JSON.parse(last_response.body)

    assert last_response.ok?

    assert_equal "<h1>Important information</h1>\n", parsed_response["details"]["body"]
    assert_equal "<h2>Header 2</h2>\n", parsed_response["details"]["parts"][0]["body"]
  end

  should "return govspeak in artefact body and part bodies if requested" do
    stub_artefact = Artefact.new(slug: 'published-artefact', owning_app: 'publisher')
    stub_answer = GuideEdition.new(body: '# Important information', parts: [Part.new(title: "Part One", body: "## Header 2", slug: "part-one")])

    Artefact.stubs(:where).with(slug: 'published-artefact').returns([stub_artefact])
    Edition.stubs(:where).with(slug: 'published-artefact', state: 'published').returns([stub_answer])

    get '/published-artefact.json?content_format=govspeak'
    parsed_response = JSON.parse(last_response.body)

    assert last_response.ok?

    assert_equal "# Important information", parsed_response["details"]["body"]
    assert_equal "## Header 2", parsed_response["details"]["parts"][0]["body"]
  end

  should "return related artefacts" do
    related_artefacts = [
      FactoryGirl.build(:artefact, slug: "related-artefact-1", name: "Pies"),
      FactoryGirl.build(:artefact, slug: "related-artefact-2", name: "Cake")
    ]
    stub_artefact = Artefact.new(slug: 'published-artefact', owning_app: 'publisher', related_artefacts: related_artefacts)
    stub_answer = AnswerEdition.new(body: '# Important information')

    Artefact.stubs(:where).with(slug: 'published-artefact').returns([stub_artefact])
    Edition.stubs(:where).with(slug: 'published-artefact', state: 'published').returns([stub_answer])

    get '/published-artefact.json'
    parsed_response = JSON.parse(last_response.body)

    assert last_response.ok?

    assert_status_field "ok", last_response
    assert_equal 2, parsed_response["related"].length

    related_artefacts.zip(parsed_response["related"]).each do |artefact, related_info|
      assert_equal artefact.name, related_info["title"]
      artefact_path = "/#{CGI.escape(artefact.slug)}.json"
      assert_equal artefact_path, URI.parse(related_info["id"]).path
      assert_equal "http://www.test.gov.uk/#{artefact.slug}", related_info["web_url"]
    end
  end

  should "return an empty list if there are no related artefacts" do
    stub_artefact = Artefact.new(slug: 'published-artefact', owning_app: 'publisher')
    stub_answer = AnswerEdition.new(body: '# Important information')

    Artefact.stubs(:where).with(slug: 'published-artefact').returns([stub_artefact])
    Edition.stubs(:where).with(slug: 'published-artefact', state: 'published').returns([stub_answer])

    get '/published-artefact.json'
    parsed_response = JSON.parse(last_response.body)

    assert last_response.ok?

    assert_status_field "ok", last_response
    assert_equal [], parsed_response["related"]
  end

  should "not look for edition if publisher not owner" do
    stub_artefact = Artefact.new(slug: 'smart-answer', owning_app: 'smart-answers')
    Artefact.stubs(:where).with(slug: 'smart-answer').returns([stub_artefact])
    Edition.expects(:where).never

    get '/smart-answer.json'

    assert last_response.ok?
    assert_status_field "ok", last_response
    refute JSON.parse(last_response.body).has_key?('format')
  end

  should "give an empty list of tags when there are no tags" do
    stub_artefact = Artefact.new(slug: "fish", owning_app: "smart-answers")
    Artefact.stubs(:where).with(slug: "fish").returns([stub_artefact])
    stub_artefact.stubs(:tags).returns([])

    get "/fish.json"

    assert last_response.ok?
    assert_status_field "ok", last_response
    assert_equal [], JSON.parse(last_response.body)["tags"]
  end

  should "list section information" do
    sections = [
      ["crime-and-justice", "Crime and justice"],
      ["crime-and-justice/batman", "Batman"]
    ]
    sections.each do |tag_id, title|
      TagRepository.put tag_id: tag_id, title: title, tag_type: "section"
    end

    stub_artefact = Artefact.new(slug: "fish", owning_app: "smart-answers")
    Artefact.stubs(:where).with(slug: "fish").returns([stub_artefact])
    section_tags = sections.map { |tag_id, _| TagRepository.load tag_id }
    stub_artefact.stubs(:tags).returns(section_tags)

    get "/fish.json"

    assert last_response.ok?
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
      assert_equal "http://www.test.gov.uk/browse/#{section[0]}", tag_info["content_with_tag"]["web_url"]
    end
  end

  should "return parts" do
    stub_artefact = Artefact.new(slug: 'published-artefact', owning_app: 'publisher')
    stub_answer = GuideEdition.new(body: '# Important information', parts: [Part.new(title: "Part One", order: 1, body: "## Header 2", slug: "part-one")])

    Artefact.stubs(:where).with(slug: 'published-artefact').returns([stub_artefact])
    Edition.stubs(:where).with(slug: 'published-artefact', state: 'published').returns([stub_answer])

    get '/published-artefact.json'
    parsed_response = JSON.parse(last_response.body)

    assert last_response.ok?

    expected_first_part = {
      "web_url" => "http://www.test.gov.uk/published-artefact/part-one",
      "slug" => "part-one",
      "order" => 1,
      "title" => "Part One",
      "body" => "<h2>Header 2</h2>\n"
    }
    assert_equal expected_first_part, parsed_response["details"]["parts"][0]
  end
end
