require 'test_helper'
require 'gds_api/test_helpers/imminence'

class PlaceFormatTest < GovUkContentApiTest
  include GdsApi::TestHelpers::Imminence

  def setup
    super
    expectation = FactoryGirl.create(:expectation)
    artefact = FactoryGirl.create(:artefact, slug: 'batman-place', owning_app: 'publisher', state: 'live')
    place_edition = FactoryGirl.create(:place_edition, 
                                place_type: "batman-place",
                                slug: artefact.slug, expectation_ids: [expectation.id],
                                minutes_to_complete: 3, panopticon_id: artefact.id, state: 'published')
  end

  def stub_imminence
    imminence_has_places("1234", "4321", {
      "slug" => "batman-place",
      "details" => [
        {
          "_id" => "5077eeb0e5274a7405000004",
          "access_notes" => "The London Passport Office is fully accessible to wheelchair users. ",
          "address1" => nil,
          "address2" => "89 Eccleston Square",
          "data_set_version" => 2,
          "email" => nil,
          "fax" => nil,
          "general_notes" => "Monday to Saturday 8.00am - 6.00pm. ",
          "geocode_error" => nil,
          "location" => {
            "longitude" => -0.14411606838362725,
            "latitude" => 51.49338734529598
          },
          "name" => "London IPS Office",
          "phone" => "0800 123 4567",
          "postcode" => "SW1V 1PN",
          "service_slug" => "find-passport-offices",
          "source_address" => " 89 Eccleston Square, London SW1V 1PN",
          "text_phone" => nil,
          "town" => "London",
          "url" => "http://www.example.com/london_ips_office"
        }
      ]
    })
  end

  it "should work with place_edition" do
    get '/batman-place.json'
    parsed_response = JSON.parse(last_response.body)

    assert last_response.ok?
    assert_base_artefact_fields(parsed_response)

    fields = parsed_response["details"]
    expected_fields = ['introduction', 'more_information', 'place_type', 'expectations']

    assert_has_expected_fields(fields, expected_fields)
  end

  describe "including place data from Imminence" do
    it "should use the supplied lat and lon parameters" do
      stub_imminence
      get '/batman-place.json?lat=1234&lon=4321'
      parsed_response = JSON.parse(last_response.body)
      assert_has_expected_fields(parsed_response["details"], ["places"])
      expected = [
        {
          "access_notes" => "The London Passport Office is fully accessible to wheelchair users. ",
          "address1" => nil,
          "address2" => "89 Eccleston Square",
          "email" => nil,
          "fax" => nil,
          "general_notes" => "Monday to Saturday 8.00am - 6.00pm. ",
          "location" => {
              "longitude" => -0.14411606838362725,
              "latitude" => 51.49338734529598
          },
          "name" => "London IPS Office",
          "phone" => "0800 123 4567",
          "postcode" => "SW1V 1PN",
          "text_phone" => nil,
          "town" => "London",
          "url" => "http://www.example.com/london_ips_office"
        }
      ]
      assert_equal expected, parsed_response["details"]["places"]
    end

    it "should show empty list if Imminence returns an empty list" do
      imminence_has_places("1234", "4321", { "slug" => "batman-place", "details" => [] })
      get '/batman-place.json?lat=1234&lon=4321'
      parsed_response = JSON.parse(last_response.body)
      assert_has_expected_fields(parsed_response["details"], ["places"])
      assert_equal [], parsed_response["details"]["places"]
    end

    it "should set an error key if the call to Imminence errors" do
      stub_request(:get, "https://imminence.test.alphagov.co.uk/places/batman-place.json").
          with(:query => {"lat" => 1234, "lng" => 4321, "limit" => "5"}).
          to_timeout
      get '/batman-place.json?lat=1234&lon=4321'
      parsed_response = JSON.parse(last_response.body)
      assert_has_expected_fields(parsed_response["details"], ["places"])
      assert_equal [{"error" => "timed_out"}], parsed_response["details"]["places"]
    end
  end
end