require 'govuk_content_api'
require 'test/unit'
require 'rack/test'
require 'mocha'

ENV['RACK_ENV'] = 'test'

class ArtefactRequestTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def test_returns_404_if_artefact_not_found
    Artefact.expects(:where).with(slug: 'bad-artefact').returns([])
    get '/bad-artefact.json'
    assert last_response.not_found?
    assert_equal 'not found', JSON.parse(last_response.body)["response"]["status"]
  end

  def test_returns_404_if_artefact_is_publication_but_never_published
    stub_artefact = Artefact.new(slug: 'unpublished-artefact', owning_app: 'publisher')
    Artefact.stubs(:where).with(slug: 'unpublished-artefact').returns([stub_artefact])
    Edition.stubs(:where).with(slug: 'unpublished-artefact', state: 'published').returns([])

    get '/unpublished-artefact.json'

    assert last_response.not_found?
    assert_equal 'not found', JSON.parse(last_response.body)["response"]["status"]
  end

  def test_returns_410_if_artefact_is_publication_but_only_archived
    stub_artefact = Artefact.new(slug: 'archived-artefact', owning_app: 'publisher')
    Artefact.stubs(:where).with(slug: 'archived-artefact').returns([stub_artefact])
    Edition.stubs(:where).with(slug: 'archived-artefact', state: 'published').returns([])

    get '/archived-artefact.json'

    assert_equal 410, last_response.status
    assert_equal 'gone', JSON.parse(last_response.body)["response"]["status"]
  end

  def test_returns_publication_data_if_published
    stub_artefact = Artefact.new(slug: 'published-artefact', owning_app: 'publisher')
    stub_answer = AnswerEdition.new(body: 'Important information')

    Artefact.stubs(:where).with(slug: 'published-artefact').returns([stub_artefact])
    Edition.stubs(:where).with(slug: 'published-artefact', state: 'published').returns([stub_answer])

    get '/published-artefact.json'
    parsed_response = JSON.parse(last_response.body)

    assert last_response.ok?
    
    assert_equal 'ok', parsed_response["response"]["status"]
    assert_equal "<p>Important information</p>\n", parsed_response["response"]["result"]["fields"]["body"]
  end

  def test_doesnt_look_for_edition_if_publisher_not_owner
    stub_artefact = Artefact.new(slug: 'smart-answer', owning_app: 'smart-answers')
    Artefact.stubs(:where).with(slug: 'smart-answer').returns([stub_artefact])
    Edition.expects(:where).never

    get '/smart-answer.json'

    assert last_response.ok?
    assert_equal 'ok', JSON.parse(last_response.body)["response"]["status"]
  end
end