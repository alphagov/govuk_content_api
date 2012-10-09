require 'test_helper'

class LicenceFormatsTest < GovUkContentApiTest
  def create_stub_licence
    stub_artefact = FactoryGirl.create(:artefact, slug: 'licence-artefact', state: 'live')
    FactoryGirl.create(:licence_edition, panopticon_id: stub_artefact.id,
      licence_identifier: '123-2-1', state: 'published')
  end

  it "should allow requests with or without .json" do
    get "/licences.json"
    assert last_response.ok?, "Didn't work with .json"

    get "/licences"
    assert last_response.ok?, "Didn't work without .json"
  end

  it "should return 404 if asked for XML" do
    get "/licences.xml"
    assert last_response.not_found?, "Tried to respond to .xml"
  end

  it "should return an empty list if not given any IDs" do
    get "/licences"
    assert last_response.ok?
    assert JSON.parse(last_response.body)['results'].empty?,
      "List of results not found or not empty"
  end

  it "should return an empty list if none of the IDs matched" do
    create_stub_licence
    get "/licences?ids=abc"
    assert last_response.ok?
    assert JSON.parse(last_response.body)['results'].empty?,
      "List of results not found or not empty"
  end

  it "should return a list of matching artefacts and licence details" do
    stub_licence = create_stub_licence
    get "/licences?ids=#{stub_licence.licence_identifier}"
    assert last_response.ok?

    parsed_response = JSON.parse(last_response.body)
    assert_equal 1, parsed_response['results'].count
    assert_equal stub_licence.licence_identifier,
      parsed_response['results'].first['details']['licence_identifier']
  end
end