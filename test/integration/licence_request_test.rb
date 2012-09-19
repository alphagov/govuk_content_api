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

  it "should return location-specific licence details for an edition with a licence identifier and snac code" do
    stub_artefact = Artefact.new(slug: 'licence-artefact', owning_app: 'publisher', business_proposition: true, need_id: 1234)
    stub_licence = LicenceEdition.new(licence_identifier: '123-2-1', licence_overview: "")

    authorities = [{
      "authorityName" => "South Ribble Borough Council",
      "authorityInteractions" => {
        "apply" => [{
          "url" => "http://www.gov.uk/licence-artefact/south-ribble/apply=1",
          "usesLicensify" => true,
          "description" => "Apply for one thing",
          "payment" => "none",
          "introductionText" => "Licence one thing"
        }]
      }
    }]
    licence_exists('123-2-1/41UH', {"isLocationSpecific" => true, "geographicalAvailability" => ["England","Wales"], "issuingAuthorities" => authorities})

    Artefact.stubs(:where).with(slug: 'licence-artefact').returns([stub_artefact])
    Edition.stubs(:where).with(slug: 'licence-artefact', state: 'published').returns([stub_licence])

    get '/licence-artefact.json?snac=41UH'

    parsed_response = JSON.parse(last_response.body)
    authority = parsed_response["details"]["licence"]["authorities"].first

    assert last_response.ok?

    assert_equal "South Ribble Borough Council", authority["name"]
    assert_equal 1, authority["actions"]["apply"].size
    assert_equal "Apply for one thing", authority["actions"]["apply"].first["description"]
    assert_equal "http://www.gov.uk/licence-artefact/south-ribble/apply=1", authority["actions"]["apply"].first["url"]
  end

it "should not query the licence api if no licence identifier is present" do
    stub_artefact = Artefact.new(slug: 'licence-artefact', owning_app: 'publisher', business_proposition: true, need_id: 1234)
    stub_licence = LicenceEdition.new(licence_identifier: nil, licence_overview: "")

    Artefact.stubs(:where).with(slug: 'licence-artefact').returns([stub_artefact])
    Edition.stubs(:where).with(slug: 'licence-artefact', state: 'published').returns([stub_licence])

    get '/licence-artefact.json'
    parsed_response = JSON.parse(last_response.body)

    assert last_response.ok?
    assert ! parsed_response["details"]["licence"].present?
  end

  it "should not return any licence details if the licence does not exist in the licence application tool" do
    stub_artefact = Artefact.new(slug: 'licence-artefact', owning_app: 'publisher', business_proposition: true, need_id: 1234)
    stub_licence = LicenceEdition.new(licence_identifier: 'blaaargh', licence_overview: "")

    licence_does_not_exist('blaaargh')

    Artefact.stubs(:where).with(slug: 'licence-artefact').returns([stub_artefact])
    Edition.stubs(:where).with(slug: 'licence-artefact', state: 'published').returns([stub_licence])

    get '/licence-artefact.json'
    parsed_response = JSON.parse(last_response.body)

    assert last_response.ok?
    assert ! parsed_response["details"]["licence"].present?
  end

  it "should not return any licence details if the licence does not exist in the licence application tool when provided with a snac code" do
    stub_artefact = Artefact.new(slug: 'licence-artefact', owning_app: 'publisher', business_proposition: true, need_id: 1234)
    stub_licence = LicenceEdition.new(licence_identifier: 'blaaargh', licence_overview: "")

    licence_does_not_exist('blaaargh/43UG')

    Artefact.stubs(:where).with(slug: 'licence-artefact').returns([stub_artefact])
    Edition.stubs(:where).with(slug: 'licence-artefact', state: 'published').returns([stub_licence])

    get '/licence-artefact.json?snac=43UG'
    parsed_response = JSON.parse(last_response.body)

    assert last_response.ok?
    assert ! parsed_response["details"][" licence"].present?
  end

  it "should not blow the stack if the api request times out" do
    stub_artefact = Artefact.new(slug: 'licence-artefact', owning_app: 'publisher', business_proposition: true, need_id: 1234)
    stub_licence = LicenceEdition.new(licence_identifier: 'blaaargh', licence_overview: "")

    licence_times_out('blaaargh/43UG')

    Artefact.stubs(:where).with(slug: 'licence-artefact').returns([stub_artefact])
    Edition.stubs(:where).with(slug: 'licence-artefact', state: 'published').returns([stub_licence])

    get '/licence-artefact.json?snac=43UG'
    parsed_response = JSON.parse(last_response.body)

    assert last_response.ok?
    assert ! parsed_response["details"][" licence"].present?
  end

  it "should not blow the stack if the api request returns an error" do
    stub_artefact = Artefact.new(slug: 'licence-artefact', owning_app: 'publisher', business_proposition: true, need_id: 1234)
    stub_licence = LicenceEdition.new(licence_identifier: 'blaaargh', licence_overview: "")

    licence_returns_error('blaaargh')

    Artefact.stubs(:where).with(slug: 'licence-artefact').returns([stub_artefact])
    Edition.stubs(:where).with(slug: 'licence-artefact', state: 'published').returns([stub_licence])

    get '/licence-artefact.json'
    parsed_response = JSON.parse(last_response.body)

    assert last_response.ok?
    assert ! parsed_response["details"][" licence"].present?
  end

end
