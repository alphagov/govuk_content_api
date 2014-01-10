require_relative '../test_helper'
require "gds_api/test_helpers/licence_application"
require "gds_api/test_helpers/asset_manager"

class FormatsRequestTest < GovUkContentApiTest
  include GdsApi::TestHelpers::LicenceApplication
  include GdsApi::TestHelpers::AssetManager

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

    expected_fields = ['description', 'alternative_title', 'body', 'need_extended_font']

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
                        'business_support_identifier', 'max_employees', 'organiser', 'continuation_link', 'will_continue_on']
    assert_has_expected_fields(fields, expected_fields)
    assert_equal "No policeman is going to give the Batmobile a ticket", fields['short_description'].strip
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
    assert_equal "#{public_web_url}/batman/part-one", fields['parts'][0]['web_url']
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
    assert_equal "#{public_web_url}/batman/overview", fields['parts'][0]['web_url']
    assert_equal "overview", fields['parts'][0]['slug']
  end

  describe "video editions" do
    before :each do
      @artefact = FactoryGirl.create(:artefact, slug: 'batman', kind: 'video', owning_app: 'publisher', sections: [@tag1.tag_id], state: 'live')
    end

    it "should work with basic video_edition" do
      video_edition = FactoryGirl.create(:video_edition, title: 'Video killed the radio star', panopticon_id: @artefact.id, slug: @artefact.slug,
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

    describe "loading the caption_file from asset-manager" do
      it "should include the caption_file details" do
        edition = FactoryGirl.create(:video_edition, :slug => @artefact.slug,
                                     :panopticon_id => @artefact.id, :state => "published",
                                     :caption_file_id => "512c9019686c82191d000001")

        asset_manager_has_an_asset("512c9019686c82191d000001", {
          "id" => "https://asset-manager.production.alphagov.co.uk/assets/512c9019686c82191d000001",
          "name" => "captions-file.xml",
          "content_type" => "application/xml",
          "file_url" => "https://assets.digital.cabinet-office.gov.uk/media/512c9019686c82191d000001/captions-file.xml",
          "state" => "clean",
        })

        get "/batman.json"
        assert last_response.ok?
        assert_status_field "ok", last_response

        parsed_response = JSON.parse(last_response.body)
        caption_file_info = {
          "web_url"=>"https://assets.digital.cabinet-office.gov.uk/media/512c9019686c82191d000001/captions-file.xml",
          "content_type"=>"application/xml"
        }
        assert_equal caption_file_info, parsed_response["details"]["caption_file"]
      end

      it "should gracefully handle failure to reach asset-manager" do
        edition = FactoryGirl.create(:video_edition, :slug => @artefact.slug,
                                     :panopticon_id => @artefact.id, :state => "published",
                                     :caption_file_id => "512c9019686c82191d000001")

        stub_request(:get, "http://asset-manager.dev.gov.uk/assets/512c9019686c82191d000001").to_return(:body => "Error", :status => 500)

        get '/batman.json'
        assert last_response.ok?

        parsed_response = JSON.parse(last_response.body)
        assert_base_artefact_fields(parsed_response)

        refute parsed_response["details"].has_key?("caption_file")
      end

      it "should not blow up with an type mismatch between the artefact and edition" do
        # This can happen when a format is being changed, and the draft edition is being preview
        edition = FactoryGirl.create(:answer_edition, :slug => @artefact.slug,
                                     :panopticon_id => @artefact.id, :state => "published")

        get '/batman.json'
        assert last_response.ok?
      end
    end
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

  describe "transaction done pages" do
    before do
      @artefact = FactoryGirl.create(:artefact, kind: 'completed_transaction', slug: 'done/batman-transaction', owning_app: 'publisher', state: 'live')
      @completed_transaction_edition = FactoryGirl.create(:completed_transaction_edition, slug: @artefact.slug,
                                  body: "It is finished",
                                  panopticon_id: @artefact.id, state: 'published')
    end

    it "should support completed transaction editions" do
      get '/done/batman-transaction.json'
      assert last_response.ok?

      parsed_response = JSON.parse(last_response.body)
      assert_base_artefact_fields(parsed_response)
      assert_equal "<p>It is finished</p>", parsed_response["details"]["body"].strip
    end

    it "should support percent-encoded slugs" do
      get '/done%2Fbatman-transaction.json'
      assert last_response.ok?

      parsed_response = JSON.parse(last_response.body)
      assert_base_artefact_fields(parsed_response)
      assert_equal "<p>It is finished</p>", parsed_response["details"]["body"].strip
    end
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
    assert_base_artefact_fields(parsed_response)

    fields = parsed_response["details"]
    expected_fields = ['introduction', 'more_information', 'place_type', 'expectations']

    assert_has_expected_fields(fields, expected_fields)
    assert_equal "<p>batman introduction</p>", fields["introduction"].strip
    assert_equal "<p>batman more_information</p>", fields["more_information"].strip
    assert_equal "batman-locations", fields["place_type"]
  end

  describe "help pages" do
    before do
      @artefact = FactoryGirl.create(:artefact, kind: 'help_page', slug: 'help/batman', owning_app: 'publisher', state: 'live')
      @help_page = FactoryGirl.create(:help_page_edition, slug: @artefact.slug, body: 'Help with batman', panopticon_id: @artefact.id, state: 'published')
    end

    it "should support help pages" do
      get '/help/batman.json'
      assert last_response.ok?

      parsed_response = JSON.parse(last_response.body)
      assert_base_artefact_fields(parsed_response)

      fields = parsed_response["details"]

      expected_fields = ['description', 'alternative_title', 'body']
      assert_has_expected_fields(fields, expected_fields)
      assert_equal "<p>Help with batman</p>\n", fields["body"]
    end

    it "should work with percent-encoded urls" do
      get '/help%2Fbatman.json'
      assert last_response.ok?

      parsed_response = JSON.parse(last_response.body)
      assert_base_artefact_fields(parsed_response)

      fields = parsed_response["details"]

      expected_fields = ['description', 'alternative_title', 'body']
      assert_has_expected_fields(fields, expected_fields)
      assert_equal "<p>Help with batman</p>\n", fields["body"]
    end
  end

  describe "campaign edition" do
    before do
      @artefact = FactoryGirl.create(:artefact, slug: 'silly-walks', kind: 'campaign', owning_app: 'publisher', state: 'live')
      @campaign = FactoryGirl.create(:campaign_edition,
                    slug: @artefact.slug,
                    body: 'Obtain a government grant to help develop your silly walk.',
                    organisation_formatted_name: "Ministry\r\nof Silly Walks",
                    organisation_url: "/government/organisations/ministry-of-silly-walks",
                    organisation_crest: "portcullis",
                    organisation_brand_colour: "hm-government",
                    small_image_id: "512c9019686c82191d000001",
                    medium_image_id: "512c9019686c82191d000002",
                    large_image_id: "512c9019686c82191d000003",
                    panopticon_id: @artefact.id,
                    state: 'published')

      asset_manager_has_an_asset("512c9019686c82191d000001", {
        "id" => "https://asset-manager.production.alphagov.co.uk/assets/512c9019686c82191d000001",
        "name" => "darth-on-a-cat.jpg",
        "content_type" => "image/jpeg",
        "file_url" => "https://assets.digital.cabinet-office.gov.uk/media/512c9019686c82191d000001/darth-on-a-cat.jpg",
        "state" => "clean",
      })

      asset_manager_has_an_asset("512c9019686c82191d000002", {
        "id" => "https://asset-manager.production.alphagov.co.uk/assets/512c9019686c82191d000002",
        "name" => "darth-on-a-cat-again.jpg",
        "content_type" => "image/jpeg",
        "file_url" => "https://assets.digital.cabinet-office.gov.uk/media/512c9019686c82191d000002/darth-on-a-cat-again.jpg",
        "state" => "clean",
      })

      asset_manager_has_an_asset("512c9019686c82191d000003", {
        "id" => "https://asset-manager.production.alphagov.co.uk/assets/512c9019686c82191d000003",
        "name" => "darth-still-on-a-cat.jpg",
        "content_type" => "image/jpeg",
        "file_url" => "https://assets.digital.cabinet-office.gov.uk/media/512c9019686c82191d000003/darth-still-on-a-cat.jpg",
        "state" => "clean",
      })
    end

    it "should support campaigns" do
      get '/silly-walks.json'
      parsed_response = JSON.parse(last_response.body)

      assert last_response.ok?
      assert_base_artefact_fields(parsed_response)

      fields = parsed_response["details"]

      expected_fields = ['description', 'alternative_title', 'body']
      assert_has_expected_fields(fields, expected_fields)

      assert_equal "<p>Obtain a government grant to help develop your silly walk.</p>\n", fields["body"]
      assert_equal "Ministry\r\nof Silly Walks", fields["organisation"]["formatted_name"]
      assert_equal "/government/organisations/ministry-of-silly-walks", fields["organisation"]["url"]
      assert_equal "portcullis", fields["organisation"]["crest"]
      assert_equal "hm-government", fields["organisation"]["brand_colour"]

      assert_equal "https://assets.digital.cabinet-office.gov.uk/media/512c9019686c82191d000001/darth-on-a-cat.jpg", fields["small_image"]["web_url"]
      assert_equal "https://assets.digital.cabinet-office.gov.uk/media/512c9019686c82191d000002/darth-on-a-cat-again.jpg", fields["medium_image"]["web_url"]
      assert_equal "https://assets.digital.cabinet-office.gov.uk/media/512c9019686c82191d000003/darth-still-on-a-cat.jpg", fields["large_image"]["web_url"]
    end

    it "should gracefully handle a missing image" do
      @campaign.update_attribute(:large_image_id, nil)
      @campaign.save!

      get '/silly-walks.json'
      parsed_response = JSON.parse(last_response.body)

      assert last_response.ok?
      assert_base_artefact_fields(parsed_response)

      fields = parsed_response["details"]

      assert fields.has_key?("small_image")
      assert fields.has_key?("medium_image")
      refute fields.has_key?("large_image")
    end
  end

  it "should work with simple smart-answers" do
    artefact = FactoryGirl.create(:artefact, :slug => 'the-bridge-of-death', :owning_app => 'publisher', :state => 'live')
    smart_answer = FactoryGirl.build(:simple_smart_answer_edition, :panopticon_id => artefact.id, :state => 'published',
                        :body => "STOP!\n-----\n\nHe who would cross the Bridge of Death  \nMust answer me  \nThese questions three  \nEre the other side he see.\n")

    n = smart_answer.nodes.build(:kind => 'question', :slug => 'what-is-your-name', :title => "What is your name?", :order => 1)
    n.options.build(:label => "Sir Lancelot of Camelot", :next_node => 'what-is-your-favorite-colour', :order => 1)
    n.options.build(:label => "Sir Galahad of Camelot", :next_node => 'what-is-your-favorite-colour', :order => 3)
    n.options.build(:label => "Sir Robin of Camelot", :next_node => 'what-is-the-capital-of-assyria', :order => 2)

    n = smart_answer.nodes.build(:kind => 'question', :slug => 'what-is-your-favorite-colour', :title => "What is your favorite colour?", :order => 3)
    n.options.build(:label => "Blue", :next_node => 'right-off-you-go')
    n.options.build(:label => "Blue... NO! YELLOOOOOOOOOOOOOOOOWWW!!!!", :next_node => 'arrrrrghhhh')

    n = smart_answer.nodes.build(:kind => 'question', :slug => 'what-is-the-capital-of-assyria', :title => "What is the capital of Assyria?", :order => 2)
    n.options.build(:label => "I don't know THAT!!", :next_node => 'arrrrrghhhh')

    n = smart_answer.nodes.build(:kind => 'outcome', :slug => 'right-off-you-go', :title => "Right, off you go.", :body => "Oh! Well, thank you.  Thank you very much", :order => 4)
    n = smart_answer.nodes.build(:kind => 'outcome', :slug => 'arrrrrghhhh', :title => "AAAAARRRRRRRRRRRRRRRRGGGGGHHH!!!!!!!", :order => 5)
    smart_answer.save!

    get '/the-bridge-of-death.json'
    assert_equal 200, last_response.status

    parsed_response = JSON.parse(last_response.body)
    assert_base_artefact_fields(parsed_response)
    details = parsed_response["details"]

    assert_has_expected_fields(details, %w(body nodes))
    assert_equal "<h2>STOP!</h2>\n\n<p>He who would cross the Bridge of Death<br />\nMust answer me<br />\nThese questions three<br />\nEre the other side he see.</p>", details["body"].strip

    nodes = details["nodes"]

    assert_equal ["What is your name?", "What is the capital of Assyria?", "What is your favorite colour?", "Right, off you go.", "AAAAARRRRRRRRRRRRRRRRGGGGGHHH!!!!!!!" ], nodes.map {|n| n["title"]}

    question1 = nodes[0]
    assert_equal "question", question1["kind"]
    assert_equal "what-is-your-name", question1["slug"]
    assert_equal ["Sir Lancelot of Camelot", "Sir Robin of Camelot", "Sir Galahad of Camelot"], question1["options"].map {|o| o["label"]}
    assert_equal ["sir-lancelot-of-camelot", "sir-robin-of-camelot", "sir-galahad-of-camelot"], question1["options"].map {|o| o["slug"]}
    assert_equal ["what-is-your-favorite-colour", "what-is-the-capital-of-assyria", "what-is-your-favorite-colour"], question1["options"].map {|o| o["next_node"]}

    outcome1 = nodes[3]
    assert_equal "outcome", outcome1["kind"]
    assert_equal "right-off-you-go", outcome1["slug"]
    assert_equal "<p>Oh! Well, thank you.  Thank you very much</p>", outcome1["body"].strip
  end
end
