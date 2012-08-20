require 'test_helper'

class FormatsRequestTest < GovUkContentApiTest
  def test_answer_edition
    artefact = FactoryGirl.create(:artefact, slug: 'batman', owning_app: 'publisher')
    answer = FactoryGirl.create(:edition, slug: artefact.slug, body: 'Important batman information', panopticon_id: artefact.id, state: 'published')
    puts artefact.inspect
    puts answer.inspect

    get '/batman.json'
    parsed_response = JSON.parse(last_response.body)

    assert last_response.ok?
    
    assert_equal 'ok', parsed_response["response"]["status"]
    assert_equal "<p>Important batman information</p>\n", parsed_response["response"]["result"]["fields"]["body"]
  end
end