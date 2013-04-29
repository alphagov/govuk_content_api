require 'test_helper'
require "gds_api/test_helpers/licence_application"

class LicenceFormatsTest < GovUkContentApiTest
  include GdsApi::TestHelpers::LicenceApplication

  def create_stub_licence
    stub_artefact = FactoryGirl.create(:artefact, slug: 'licence-artefact', state: 'live')
    FactoryGirl.create(:licence_edition, panopticon_id: stub_artefact.id,
      licence_identifier: '123-2-1', licence_short_description: "A licence for stuff", state: 'published')
  end

  it "should return an empty list if not given any IDs" do
    get "/licences.json"
    assert last_response.ok?
    parsed_response = JSON.parse(last_response.body)
    assert parsed_response['results'].empty?,
      "List of results not found or not empty"

    assert_has_values parsed_response, "total" => 0, "current_page" => 1,
                                       "pages" => 1
  end

  it "should return an empty list if none of the IDs matched" do
    create_stub_licence
    get "/licences.json?ids=abc"
    assert last_response.ok?
    parsed_response = JSON.parse(last_response.body)
    assert parsed_response['results'].empty?,
      "List of results not found or not empty"

    assert_has_values parsed_response, "total" => 0, "current_page" => 1,
                                       "pages" => 1
  end

  it "should return a list of matching artefacts and licence details" do
    stub_licence = create_stub_licence
    get "/licences.json?ids=#{stub_licence.licence_identifier}"
    assert last_response.ok?

    parsed_response = JSON.parse(last_response.body)
    assert_equal 1, parsed_response['results'].count
    assert_equal stub_licence.licence_identifier,
      parsed_response['results'].first['details']['licence_identifier']
    assert_equal stub_licence.licence_short_description,
      parsed_response['results'].first['details']['licence_short_description']

    assert_has_values parsed_response, "total" => 1, "current_page" => 1,
                                       "pages" => 1
  end

  it "should not clobber artefact requests that start with 'licences'" do
    artefact = FactoryGirl.create(:artefact, slug: 'licences-to-play-music', owning_app: 'publisher', state: 'live')
    licence_edition = FactoryGirl.create(:licence_edition, slug: artefact.slug, licence_short_description: 'Music licence',
                                panopticon_id: artefact.id, state: 'published', licence_identifier: "123-4-5")
    licence_exists('123-4-5', { })

    get '/licences-to-play-music.json'
    assert last_response.ok?

    parsed_response = JSON.parse(last_response.body)
    assert_equal "Music licence", parsed_response["details"]["licence_short_description"]
  end
end
