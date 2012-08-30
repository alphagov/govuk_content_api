require 'test_helper'

class FormatsRequestTest < GovUkContentApiTest

  def setup
    super
    @tag1 = FactoryGirl.create(:tag, tag_id: 'crime')
    @tag2 = FactoryGirl.create(:tag, tag_id: 'crime/batman')
  end

  def _assert_base_response_info(parsed_response)
    assert_equal 'ok', parsed_response["_response_info"]["status"]
    assert parsed_response.has_key?('title')
    assert parsed_response.has_key?('id')
    assert parsed_response.has_key?('tag_ids')
  end

  def _assert_has_expected_fields(parsed_response, fields)
    fields.each do |field|
      assert parsed_response.has_key?(field), "Field #{field} is MISSING"
    end
  end

  should "answer_edition" do
    artefact = FactoryGirl.create(:artefact, slug: 'batman', owning_app: 'publisher', sections: [@tag1.tag_id])
    answer = FactoryGirl.create(:edition, slug: artefact.slug, body: 'Important batman information', panopticon_id: artefact.id, state: 'published')

    get '/batman.json'
    parsed_response = JSON.parse(last_response.body)

    assert last_response.ok?
    _assert_base_response_info(parsed_response)

    fields = parsed_response["details"]

    expected_fields = ['alternative_title', 'overview', 'body', 'section']

    _assert_has_expected_fields(fields, expected_fields)    
    assert_equal "<p>Important batman information</p>\n", fields["body"]
  end

  should "business_support_edition" do
    artefact = FactoryGirl.create(:artefact, slug: 'batman', owning_app: 'publisher', sections: [@tag1.tag_id])
    business_support = FactoryGirl.create(:business_support_edition, slug: artefact.slug, 
                                short_description: "No policeman's going to give the Batmobile a ticket", min_value: 100, 
                                max_value: 1000, panopticon_id: artefact.id, state: 'published')
    business_support.parts[0].body = "Lalalala"
    business_support.save!

    get '/batman.json'
    parsed_response = JSON.parse(last_response.body)

    assert last_response.ok?
    _assert_base_response_info(parsed_response)

    fields = parsed_response["details"]
    expected_fields = ['alternative_title', 'overview', 'section', 
                        'short_description', 'min_value', 'max_value', 'parts']
    _assert_has_expected_fields(fields, expected_fields)
    assert_false fields.has_key?('body')
    assert_equal "No policeman's going to give the Batmobile a ticket", fields['short_description']
    assert_equal "<p>Lalalala</p>\n", fields['parts'][0]["body"]
  end

  should "guide_edition" do
    artefact = FactoryGirl.create(:artefact, slug: 'batman', owning_app: 'publisher', sections: [@tag1.tag_id])
    guide_edition = FactoryGirl.create(:guide_edition_with_two_govspeak_parts, slug: artefact.slug, 
                                panopticon_id: artefact.id, state: 'published')
    guide_edition.save!

    get '/batman.json'
    parsed_response = JSON.parse(last_response.body)

    assert last_response.ok?
    _assert_base_response_info(parsed_response)

    fields = parsed_response["details"]
    expected_fields = ['alternative_title', 'overview', 'section', 'parts']

    _assert_has_expected_fields(fields, expected_fields)
    assert_false fields.has_key?('body')
    assert_equal "Some Part Title!", fields['parts'][0]['title']
    assert_equal "<p>This is some <strong>version</strong> text.</p>\n", fields['parts'][0]['body']
    assert_equal "part-one", fields['parts'][0]['id']
  end

  should "programme_edition" do
    artefact = FactoryGirl.create(:artefact, slug: 'batman', owning_app: 'publisher', sections: [@tag1.tag_id])
    programme_edition = FactoryGirl.create(:programme_edition, slug: artefact.slug, 
                                panopticon_id: artefact.id, state: 'published')
    programme_edition.save!

    get '/batman.json'
    parsed_response = JSON.parse(last_response.body)

    assert last_response.ok?
    _assert_base_response_info(parsed_response)

    fields = parsed_response["details"]
    expected_fields = ['alternative_title', 'overview', 'section', 'parts']

    _assert_has_expected_fields(fields, expected_fields)
    assert_false fields.has_key?('body')
    assert_equal "Overview", fields['parts'][0]['title']
    assert_equal "overview", fields['parts'][0]['id']
  end

  should "video_edition" do
    artefact = FactoryGirl.create(:artefact, slug: 'batman', owning_app: 'publisher', sections: [@tag1.tag_id])
    video_edition = VideoEdition.create!(slug: artefact.slug, title: 'Video killed the radio star', body: 'Important batman information',
                                video_summary: 'I am a video summary', video_url: 'http://somevideourl.com', panopticon_id: artefact.id, state: 'published')
    get '/batman.json'
    parsed_response = JSON.parse(last_response.body)

    assert last_response.ok?
    _assert_base_response_info(parsed_response)

    fields = parsed_response["details"]

    expected_fields = ['alternative_title', 'overview', 'body', 'section', 'video_url', 'video_summary']

    _assert_has_expected_fields(fields, expected_fields)
    assert_equal "<p>Important batman information</p>\n", fields["body"]
    assert_equal "I am a video summary", fields["video_summary"]
    assert_equal "http://somevideourl.com", fields["video_url"]
  end

  should "licence_edition" do
    artefact = FactoryGirl.create(:artefact, slug: 'batman-licence', owning_app: 'publisher', sections: [@tag1.tag_id])
    licence_edition = FactoryGirl.create(:licence_edition, slug: artefact.slug, licence_short_description: 'Batman licence', 
                                licence_overview: 'Not just anyone can be Batman', panopticon_id: artefact.id, state: 'published')
    get '/batman-licence.json'
    parsed_response = JSON.parse(last_response.body)

    assert last_response.ok?
    _assert_base_response_info(parsed_response)

    fields = parsed_response["details"]
    expected_fields = ['alternative_title', 'section', 'licence_overview', 'licence_short_description', 'licence_identifier']

    _assert_has_expected_fields(fields, expected_fields)
    assert_equal "Not just anyone can be Batman", fields["licence_overview"]
    assert_equal "Batman licence", fields["licence_short_description"]
  end

  should "local_transaction_edition" do
    service = FactoryGirl.create(:local_service)
    expectation = FactoryGirl.create(:expectation)
    artefact = FactoryGirl.create(:artefact, slug: 'batman-transaction', owning_app: 'publisher', sections: [@tag1.tag_id])
    local_transaction_edition = FactoryGirl.create(:local_transaction_edition, slug: artefact.slug, lgil_override: 3345,
                                expectation_ids: [expectation.id], minutes_to_complete: 3,
                                panopticon_id: artefact.id, state: 'published')
    get '/batman-transaction.json'
    parsed_response = JSON.parse(last_response.body)

    assert last_response.ok?
    _assert_base_response_info(parsed_response)

    fields = parsed_response["details"]
    expected_fields = ['alternative_title', 'section', 'lgsl_code', 'lgil_override', 'introduction', 'more_information', 
                        'minutes_to_complete', 'expectation_ids']

    _assert_has_expected_fields(fields, expected_fields)
  end

  should "transaction_edition" do
    expectation = FactoryGirl.create(:expectation)
    artefact = FactoryGirl.create(:artefact, slug: 'batman-transaction', owning_app: 'publisher', sections: [@tag1.tag_id])
    transaction_edition = FactoryGirl.create(:transaction_edition, slug: artefact.slug, 
                                expectation_ids: [expectation.id], minutes_to_complete: 3,
                                panopticon_id: artefact.id, state: 'published')
    get '/batman-transaction.json'
    parsed_response = JSON.parse(last_response.body)

    assert last_response.ok?
    _assert_base_response_info(parsed_response)

    fields = parsed_response["details"]
    expected_fields = ['alternate_methods', 'section', 'will_continue_on', 'link', 'introduction', 'more_information', 
                        'expectation_ids']

    _assert_has_expected_fields(fields, expected_fields)
  end

  should "place_edition" do
    expectation = FactoryGirl.create(:expectation)
    artefact = FactoryGirl.create(:artefact, slug: 'batman-place', owning_app: 'publisher', sections: [@tag1.tag_id])
    place_edition = FactoryGirl.create(:place_edition, slug: artefact.slug, expectation_ids: [expectation.id],
                                minutes_to_complete: 3, panopticon_id: artefact.id, state: 'published')
    get '/batman-place.json'
    parsed_response = JSON.parse(last_response.body)

    assert last_response.ok?
    _assert_base_response_info(parsed_response)

    fields = parsed_response["details"]
    expected_fields = ['section', 'introduction', 'more_information', 'place_type', 'expectation_ids']

    _assert_has_expected_fields(fields, expected_fields)
  end

end
