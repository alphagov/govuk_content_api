require 'test_helper'

class ArtefactRequestTest < GovUkContentApiTest
  should "return 404 if artefact not found" do
    Artefact.expects(:where).with(slug: 'bad-artefact').returns([])
    get '/bad-artefact.json'
    assert last_response.not_found?
    assert_equal 'not found', JSON.parse(last_response.body)["response"]["status"]
  end

  should "return 404 if artefact is publication but never published" do
    stub_artefact = Artefact.new(slug: 'unpublished-artefact', owning_app: 'publisher')
    Artefact.stubs(:where).with(slug: 'unpublished-artefact').returns([stub_artefact])
    Edition.stubs(:where).with(slug: 'unpublished-artefact', state: 'published').returns([])
    Edition.stubs(:where).with(slug: 'unpublished-artefact', state: 'archived').returns([])

    get '/unpublished-artefact.json'

    assert last_response.not_found?
    assert_equal 'not found', JSON.parse(last_response.body)["response"]["status"]
  end

  should "return 410 if artefact is publication but only archived" do
    stub_artefact = Artefact.new(slug: 'archived-artefact', owning_app: 'publisher')
    Artefact.stubs(:where).with(slug: 'archived-artefact').returns([stub_artefact])
    Edition.stubs(:where).with(slug: 'archived-artefact', state: 'published').returns([])
    Edition.stubs(:where).with(slug: 'archived-artefact', state: 'archived').returns(['not empty'])

    get '/archived-artefact.json'

    assert_equal 410, last_response.status
    assert_equal 'gone', JSON.parse(last_response.body)["response"]["status"]
  end

  should "return publication data if published" do
    stub_artefact = Artefact.new(slug: 'published-artefact', owning_app: 'publisher')
    stub_answer = AnswerEdition.new(body: '# Important information')

    Artefact.stubs(:where).with(slug: 'published-artefact').returns([stub_artefact])
    Edition.stubs(:where).with(slug: 'published-artefact', state: 'published').returns([stub_answer])

    get '/published-artefact.json'
    parsed_response = JSON.parse(last_response.body)

    assert last_response.ok?
    
    assert_equal 'ok', parsed_response["response"]["status"]
    assert_equal "<h1>Important information</h1>\n", parsed_response["response"]["result"]["fields"]["body"]
  end

  should "convert artefact body and part bodies to html" do
    stub_artefact = Artefact.new(slug: 'published-artefact', owning_app: 'publisher')
    stub_answer = GuideEdition.new(body: '# Important information', parts: [Part.new(title: "Part One", body: "## Header 2", slug: "part-one")])

    Artefact.stubs(:where).with(slug: 'published-artefact').returns([stub_artefact])
    Edition.stubs(:where).with(slug: 'published-artefact', state: 'published').returns([stub_answer])

    get '/published-artefact.json'
    parsed_response = JSON.parse(last_response.body)

    assert last_response.ok?

    assert_equal "<h1>Important information</h1>\n", parsed_response["response"]["result"]["fields"]["body"]
    assert_equal "<h2>Header 2</h2>\n", parsed_response["response"]["result"]["fields"]["parts"][0]["body"]
  end

  should "return govspeak in artefact body and part bodies if requested" do
    stub_artefact = Artefact.new(slug: 'published-artefact', owning_app: 'publisher')
    stub_answer = GuideEdition.new(body: '# Important information', parts: [Part.new(title: "Part One", body: "## Header 2", slug: "part-one")])

    Artefact.stubs(:where).with(slug: 'published-artefact').returns([stub_artefact])
    Edition.stubs(:where).with(slug: 'published-artefact', state: 'published').returns([stub_answer])

    get '/published-artefact.json?content_format=govspeak'
    parsed_response = JSON.parse(last_response.body)

    assert last_response.ok?

    assert_equal "# Important information", parsed_response["response"]["result"]["fields"]["body"]
    assert_equal "## Header 2", parsed_response["response"]["result"]["fields"]["parts"][0]["body"]
  end

  should "return related artefact slugs in related_artefact_ids" do
    related_artefacts = [
      FactoryGirl.build(:artefact, slug: "related-artefact-1"),
      FactoryGirl.build(:artefact, slug: "related-artefact-2")
    ]
    stub_artefact = Artefact.new(slug: 'published-artefact', owning_app: 'publisher', related_artefacts: related_artefacts)
    stub_answer = AnswerEdition.new(body: '# Important information')

    Artefact.stubs(:where).with(slug: 'published-artefact').returns([stub_artefact])
    Edition.stubs(:where).with(slug: 'published-artefact', state: 'published').returns([stub_answer])

    get '/published-artefact.json'
    parsed_response = JSON.parse(last_response.body)

    assert last_response.ok?
    
    assert_equal 'ok', parsed_response["response"]["status"]
    assert_equal ["related-artefact-1", "related-artefact-2"], parsed_response["response"]["result"]["related_artefact_ids"]
  end

  should "not look for edition if publisher not owner" do
    stub_artefact = Artefact.new(slug: 'smart-answer', owning_app: 'smart-answers')
    Artefact.stubs(:where).with(slug: 'smart-answer').returns([stub_artefact])
    Edition.expects(:where).never

    get '/smart-answer.json'

    assert last_response.ok?
    assert_equal 'ok', JSON.parse(last_response.body)["response"]["status"]
    assert_false JSON.parse(last_response.body)["response"]["result"].has_key?('format')
  end
end