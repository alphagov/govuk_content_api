require 'test_helper'
require "gds_api/test_helpers/licence_application"

class FormatsRequestTest < GovUkContentApiTest
  include GdsApi::TestHelpers::LicenceApplication

  def setup
    super
    @tag1 = FactoryGirl.create(:tag, tag_id: 'crime')
    @tag2 = FactoryGirl.create(:tag, tag_id: 'crime/batman')
  end

  it "should work with answer_edition" do
    artefact = FactoryGirl.create(:artefact, slug: 'batman', owning_app: 'publisher', sections: [@tag1.tag_id], state: 'live')
    answer = FactoryGirl.create(:edition, slug: artefact.slug, body: 'Important batman information', panopticon_id: artefact.id, state: 'published')

    get '/batman.json'
    parsed_response = JSON.parse(last_response.body)

    assert last_response.ok?
    assert_base_artefact_fields(parsed_response)

    fields = parsed_response["details"]

    expected_fields = ['description', 'alternative_title', 'body']

    assert_has_expected_fields(fields, expected_fields)
    assert_equal "<p>Important batman information</p>\n", fields["body"]
  end

  it "should work with business_support_edition" do
    artefact = FactoryGirl.create(:artefact, slug: 'batman', owning_app: 'publisher', sections: [@tag1.tag_id], state: 'live')
    business_support = FactoryGirl.create(:business_support_edition, slug: artefact.slug,
                                short_description: "No policeman is going to give the Batmobile a ticket",
                                body: "batman body", eligibility: "batman eligibility", evaluation: "batman evaluation",
                                additional_information: "batman additional_information",
                                min_value: 100, max_value: 1000, panopticon_id: artefact.id, state: 'published',
                                business_support_identifier: 'enterprise-finance-guarantee', max_employees: 10,
                                organiser: "Someone", continuation_link: "http://www.example.com/scheme", will_continue_on: "Example site")
    business_support.save!

    get '/batman.json'
    parsed_response = JSON.parse(last_response.body)

    assert last_response.ok?
    assert_base_artefact_fields(parsed_response)

    fields = parsed_response["details"]
    expected_fields = ['alternative_title', 'description', 'body',
                        'short_description', 'min_value', 'max_value', 'eligibility', 'evaluation', 'additional_information',
                        'business_support_identifier', 'max_employees', 'organiser', 'continuation_link', 'will_continue_on', 'contact_details']
    assert_has_expected_fields(fields, expected_fields)
    assert_equal "<p>No policeman is going to give the Batmobile a ticket</p>", fields['short_description'].strip
    assert_equal "enterprise-finance-guarantee", fields['business_support_identifier']
    assert_equal "No policeman is going to give the Batmobile a ticket", fields['short_description']
    assert_equal "<p>batman body</p>", fields['body'].strip
    assert_equal "<p>batman eligibility</p>", fields['eligibility'].strip
    assert_equal "<p>batman evaluation</p>", fields['evaluation'].strip
    assert_equal "<p>batman additional_information</p>", fields['additional_information'].strip

    assert_equal 100, fields["min_value"]
    assert_equal 1000, fields["max_value"]
    assert_equal 10, fields["max_employees"]
    assert_equal "Someone", fields["organiser"]
    assert_equal "Example site", fields["will_continue_on"]
    assert_equal "http://www.example.com/scheme", fields["continuation_link"]
  end

  it "should work with guide_edition" do
    artefact = FactoryGirl.create(:artefact, slug: 'batman', owning_app: 'publisher', sections: [@tag1.tag_id], state: 'live')
    guide_edition = FactoryGirl.create(:guide_edition_with_two_govspeak_parts, slug: artefact.slug,
                                panopticon_id: artefact.id, state: 'published')
    guide_edition.save!

    get '/batman.json'
    parsed_response = JSON.parse(last_response.body)

    assert last_response.ok?
    assert_base_artefact_fields(parsed_response)

    fields = parsed_response["details"]
    expected_fields = ['alternative_title', 'description', 'parts']

    assert_has_expected_fields(fields, expected_fields)
    refute fields.has_key?('body')
    assert_equal "Some Part Title!", fields['parts'][0]['title']
    assert_equal "<p>This is some <strong>version</strong> text.</p>\n", fields['parts'][0]['body']
    assert_equal "http://www.test.gov.uk/batman/part-one", fields['parts'][0]['web_url']
    assert_equal "part-one", fields['parts'][0]['slug']
  end

  it "should work with programme_edition" do
    artefact = FactoryGirl.create(:artefact, slug: 'batman', owning_app: 'publisher', sections: [@tag1.tag_id], state: 'live')
    programme_edition = FactoryGirl.create(:programme_edition, slug: artefact.slug,
                                panopticon_id: artefact.id, state: 'published')
    programme_edition.save!

    get '/batman.json'
    parsed_response = JSON.parse(last_response.body)

    assert last_response.ok?
    assert_base_artefact_fields(parsed_response)

    fields = parsed_response["details"]
    expected_fields = ['alternative_title', 'description', 'parts']

    assert_has_expected_fields(fields, expected_fields)
    refute fields.has_key?('body')
    assert_equal "Overview", fields['parts'][0]['title']
    assert_equal "http://www.test.gov.uk/batman/overview", fields['parts'][0]['web_url']
    assert_equal "overview", fields['parts'][0]['slug']
  end

  it "should work with video_edition" do
    artefact = FactoryGirl.create(:artefact, slug: 'batman', owning_app: 'publisher', sections: [@tag1.tag_id], state: 'live')
    video_edition = FactoryGirl.create(:video_edition, title: 'Video killed the radio star', panopticon_id: artefact.id, slug: artefact.slug,
                                       video_summary: 'I am a video summary', video_url: 'http://somevideourl.com',
                                       body: "Video description\n------", state: 'published')

    get '/batman.json'
    parsed_response = JSON.parse(last_response.body)

    assert last_response.ok?
    assert_base_artefact_fields(parsed_response)

    fields = parsed_response["details"]

    expected_fields = %w(alternative_title description video_url video_summary body)

    assert_has_expected_fields(fields, expected_fields)
    assert_equal "I am a video summary", fields["video_summary"]
    assert_equal "http://somevideourl.com", fields["video_url"]
    assert_equal "<h2>Video description</h2>\n", fields["body"]
  end

  it "should work with licence_edition" do
    artefact = FactoryGirl.create(:artefact, slug: 'batman-licence', owning_app: 'publisher', sections: [@tag1.tag_id], state: 'live')
    licence_edition = FactoryGirl.create(:licence_edition, slug: artefact.slug, licence_short_description: 'Batman licence',
                                licence_overview: 'Not just anyone can be Batman', panopticon_id: artefact.id, state: 'published',
                                will_continue_on: 'The Batman', continuation_link: 'http://www.batman.com', licence_identifier: "123-4-5")
    licence_exists('123-4-5', { })

    get '/batman-licence.json'
    parsed_response = JSON.parse(last_response.body)

    assert last_response.ok?
    assert_base_artefact_fields(parsed_response)

    fields = parsed_response["details"]
    expected_fields = ['alternative_title', 'licence_overview', 'licence_short_description', 'licence_identifier', 'will_continue_on', 'continuation_link']

    assert_has_expected_fields(fields, expected_fields)
    assert_equal "<p>Not just anyone can be Batman</p>", fields["licence_overview"].strip
    assert_equal "Batman licence", fields["licence_short_description"]
    assert_equal "123-4-5", fields["licence_identifier"]
    assert_equal "The Batman", fields["will_continue_on"]
    assert_equal "http://www.batman.com", fields["continuation_link"]
  end

  it "should work with local_transaction_edition" do
    service = FactoryGirl.create(:local_service, lgsl_code: 42)
    expectation = FactoryGirl.create(:expectation)
    artefact = FactoryGirl.create(:artefact, slug: 'batman-transaction', owning_app: 'publisher', sections: [@tag1.tag_id], state: 'live')
    local_transaction_edition = FactoryGirl.create(:local_transaction_edition, slug: artefact.slug, lgsl_code: 42, lgil_override: 3345,
                                expectation_ids: [expectation.id], minutes_to_complete: 3,
                                introduction: "batman introduction", more_information: "batman more_information",
                                panopticon_id: artefact.id, state: 'published')
    get '/batman-transaction.json'
    parsed_response = JSON.parse(last_response.body)

    assert last_response.ok?
    assert_base_artefact_fields(parsed_response)

    fields = parsed_response["details"]
    expected_fields = ['alternative_title', 'lgsl_code', 'lgil_override', 'introduction', 'more_information',
                        'minutes_to_complete', 'expectations']

    assert_has_expected_fields(fields, expected_fields)
    assert_equal "<p>batman introduction</p>", fields["introduction"].strip
    assert_equal "<p>batman more_information</p>", fields["more_information"].strip
    assert_equal "3", fields["minutes_to_complete"]
    assert_equal 42, fields["lgsl_code"]
    assert_equal 3345, fields["lgil_override"]
  end

  it "should work with transaction_edition" do
    expectation = FactoryGirl.create(:expectation)
    artefact = FactoryGirl.create(:artefact, slug: 'batman-transaction', owning_app: 'publisher', sections: [@tag1.tag_id], state: 'live')
    transaction_edition = FactoryGirl.create(:transaction_edition, slug: artefact.slug,
                                expectation_ids: [expectation.id], minutes_to_complete: 3,
                                introduction: "batman introduction", more_information: "batman more_information",
                                alternate_methods: "batman alternate_methods",
                                will_continue_on: "A Site", link: "http://www.example.com/foo",
                                panopticon_id: artefact.id, state: 'published')
    get '/batman-transaction.json'
    parsed_response = JSON.parse(last_response.body)

    assert last_response.ok?
    assert_base_artefact_fields(parsed_response)

    fields = parsed_response["details"]
    expected_fields = ['alternate_methods', 'will_continue_on', 'link', 'introduction', 'more_information',
                        'expectations']

    assert_has_expected_fields(fields, expected_fields)
    assert_equal "<p>batman introduction</p>", fields["introduction"].strip
    assert_equal "<p>batman more_information</p>", fields["more_information"].strip
    assert_equal "<p>batman alternate_methods</p>", fields["alternate_methods"].strip
    assert_equal "3", fields["minutes_to_complete"]
    assert_equal "A Site", fields["will_continue_on"]
    assert_equal "http://www.example.com/foo", fields["link"]
  end

  it "should work with place_edition" do
    expectation = FactoryGirl.create(:expectation)
    artefact = FactoryGirl.create(:artefact, slug: 'batman-place', owning_app: 'publisher', sections: [@tag1.tag_id], state: 'live')
    place_edition = FactoryGirl.create(:place_edition, slug: artefact.slug, expectation_ids: [expectation.id],
                                introduction: "batman introduction", more_information: "batman more_information",
                                place_type: "batman-locations",
                                minutes_to_complete: 3, panopticon_id: artefact.id, state: 'published')
    get '/batman-place.json'
    parsed_response = JSON.parse(last_response.body)

    assert last_response.ok?
    _assert_base_response_info(parsed_response)

    fields = parsed_response["details"]
    expected_fields = ['introduction', 'more_information', 'place_type', 'expectations']

    _assert_has_expected_fields(fields, expected_fields)
    assert_equal "<p>batman introduction</p>", fields["introduction"].strip
    assert_equal "<p>batman more_information</p>", fields["more_information"].strip
    assert_equal "batman-locations", fields["place_type"]
  end
end
