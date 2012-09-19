require 'test_helper'
require "gds_api/test_helpers/licence_application"

class LicenceRequestTest < GovUkContentApiTest
  include GdsApi::TestHelpers::LicenceApplication

  it "should return full licence details for an edition with a licence identifier" do
    stub_artefact = Artefact.new(slug: 'licence-artefact', owning_app: 'publisher', business_proposition: true, need_id: 1234)
    stub_licence = LicenceEdition.new(licence_identifier: '123-2-1', licence_overview: "")

    authorities = [{
      "authorityName" => "Authority",
      "authorityInteractions" => {
        "apply" => [{
          "url" => "http://gov.uk/apply",
          "usesLicensify" => true,
          "description" => "Apply for all the things",
          "payment" => "none",
          "introductionText" => "Licence all the things"
        }],
        "renew" => [{
          "url" => "http://gov.uk/renew",
          "usesLicensify" => true,
          "description" => "Renew all the things",
          "payment" => "none",
          "introductionText" => "Licence all the things"
        }]
      }
    }]
    licence_exists('123-2-1', {"isLocationSpecific" => false, "geographicalAvailability" => ["England","Wales"], "issuingAuthorities" => authorities})

    Artefact.stubs(:where).with(slug: 'licence-artefact').returns([stub_artefact])
    Edition.stubs(:where).with(slug: 'licence-artefact', state: 'published').returns([stub_licence])

    get '/licence-artefact.json'
    parsed_response = JSON.parse(last_response.body)

    assert last_response.ok?
    assert parsed_response["details"]["licence"].present?

    assert_equal false, parsed_response["details"]["licence"]["location_specific"]
    assert_equal ["England","Wales"], parsed_response["details"]["licence"]["availability"]

    assert_equal ['Authority'], parsed_response["details"]["licence"]["authorities"].map {|r| r['name']}
    assert_equal ['Apply for all the things', 'Renew all the things'], parsed_response["details"]["licence"]["authorities"].first["actions"].map {|k,v| v.first["description"] }
  end

end
