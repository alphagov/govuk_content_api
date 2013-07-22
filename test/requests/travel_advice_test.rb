require_relative '../test_helper'
require 'gds_api/test_helpers/asset_manager'

class TravelAdviceTest < GovUkContentApiTest
  include GdsApi::TestHelpers::AssetManager

  describe "loading the travel-advice index artefact" do
    before do
      @artefact = FactoryGirl.create(:artefact, :slug => 'foreign-travel-advice', :state => 'live', :need_id => '133',
                                     :owning_app => 'travel-advice-publisher', :rendering_app => 'frontend',
                                     :name => 'Foreign travel advice', :description => 'Oh I do want to live beside the seaside!')
    end

    it "should return the normal artefact fields" do
      get '/foreign-travel-advice.json'
      assert last_response.ok?

      parsed_response = JSON.parse(last_response.body)

      assert_base_artefact_fields(parsed_response)
      assert_equal 'Foreign travel advice', parsed_response['title']

      details = parsed_response["details"]
      expected_fields = ['description', 'need_id']
      assert_has_expected_fields(details, expected_fields)
      assert_equal 'Oh I do want to live beside the seaside!', details['description']
    end

    it "should include an alphabetical list of countries with published editions" do
      edition1 = FactoryGirl.create(:published_travel_advice_edition, country_slug: 'afghanistan',
                                    change_description: "Some stuff changed", published_at: 2.days.ago, synonyms: ["bar", "foo"])
      edition2 = FactoryGirl.create(:published_travel_advice_edition, country_slug: 'angola')
      edition3 = FactoryGirl.create(:published_travel_advice_edition, country_slug: 'andorra')

      get '/foreign-travel-advice.json'
      assert last_response.ok?

      parsed_response = JSON.parse(last_response.body)

      countries = parsed_response['details']['countries']

      assert_equal 3, countries.length

      assert_equal ["Afghanistan", "Andorra", "Angola"], countries.map {|c| c["name"]}

      first = countries.first
      assert_equal "Afghanistan", first["name"]
      assert_equal "afghanistan", first["identifier"]
      assert_equal "http://example.org/foreign-travel-advice%2Fafghanistan.json", first["id"]
      assert_equal "https://www.gov.uk/foreign-travel-advice/afghanistan", first["web_url"]
      assert_equal edition1.published_at.xmlschema, first["updated_at"]
      assert_equal "Some stuff changed", first["change_description"]
      assert_equal ["bar", "foo"], first["synonyms"]
    end

    it "should not include countries without published editions" do
      edition1 = FactoryGirl.create(:archived_travel_advice_edition, country_slug: 'afghanistan')
      edition2 = FactoryGirl.create(:draft_travel_advice_edition, country_slug: 'angola')
      edition3 = FactoryGirl.create(:published_travel_advice_edition, country_slug: 'andorra')

      get '/foreign-travel-advice.json'
      assert last_response.ok?

      parsed_response = JSON.parse(last_response.body)

      countries = parsed_response['details']['countries']
      assert_equal 1, countries.length
      assert_equal ["Andorra"], countries.map {|c| c["name"]}
    end

    it "should not include published editions for a non-existent country" do
      edition1 = FactoryGirl.create(:published_travel_advice_edition, country_slug: 'afghanistan',
                                  alert_status: ["avoid_all_but_essential_travel_to_parts","avoid_all_travel_to_parts"])
      edition2 = FactoryGirl.create(:published_travel_advice_edition, country_slug: 'angola')
      edition3 = FactoryGirl.create(:published_travel_advice_edition, country_slug: 'narnia')

      get '/foreign-travel-advice.json'
      assert last_response.ok?

      parsed_response = JSON.parse(last_response.body)

      countries = parsed_response['details']['countries']
      assert_equal 2, countries.length
      assert_equal ["Afghanistan", "Angola"], countries.map {|c| c["name"]}
    end
  end


  describe "loading data for a travel advice country page" do

    it "should return details for a country with published advice" do
      artefact = FactoryGirl.create(:artefact, slug: 'foreign-travel-advice/aruba', state: 'live',
                                    kind: 'travel-advice', owning_app: 'travel-advice-publisher', name: "Aruba travel advice",
                                    description: "This is the travel advice for people planning a visit to Aruba.")
      edition = FactoryGirl.build(:travel_advice_edition, country_slug: 'aruba',
                                  title: "Travel advice for Aruba", overview: "This is the travel advice for people planning a visit to Aruba.",
                                  change_description: "Some stuff changed",
                                  summary: "This is the summary\n------\n",
                                  alert_status: ["avoid_all_but_essential_travel_to_parts","avoid_all_travel_to_parts"])
      edition.parts.build(title: "Part One", slug: 'part-one', body: "This is part one\n------\n")
      edition.parts.build(title: "Part Two", slug: 'part-two', body: "And some more stuff in part 2.")
      edition.save!
      Timecop.travel(2.days.ago) do
        edition.publish!
      end

      get '/foreign-travel-advice/aruba.json'
      assert last_response.ok?

      parsed_response = JSON.parse(last_response.body)

      assert_base_artefact_fields(parsed_response)
      assert_equal 'travel-advice', parsed_response["format"]
      assert_equal 'Travel advice for Aruba', parsed_response["title"]
      assert_equal edition.published_at.xmlschema, parsed_response["updated_at"]

      details = parsed_response["details"]
      assert_equal 'This is the travel advice for people planning a visit to Aruba.', details['description']
      assert_equal edition.reviewed_at, details["reviewed_at"]
      assert_equal 'Some stuff changed', details['change_description']
      assert_equal '<h2>This is the summary</h2>', details['summary'].strip
      assert_equal ["avoid_all_but_essential_travel_to_parts","avoid_all_travel_to_parts"], details['alert_status']

      # Country details
      assert_equal({"name" => "Aruba", "slug" => "aruba"}, details["country"])

      # Parts
      parts = details["parts"]
      assert_equal 2, parts.length

      assert_equal "Part One", parts[0]["title"]
      assert_equal "part-one", parts[0]["slug"]
      assert_equal "<h2>This is part one</h2>", parts[0]["body"].strip

      assert_equal "Part Two", parts[1]["title"]
      assert_equal "part-two", parts[1]["slug"]
      assert_equal "<p>And some more stuff in part 2.</p>", parts[1]["body"].strip
    end

    it "should work with % encoded slugs" do
      artefact = FactoryGirl.create(:artefact, slug: 'foreign-travel-advice/aruba', state: 'live',
                                    kind: 'travel-advice', owning_app: 'travel-advice-publisher', name: "Aruba travel advice",
                                    description: "This is the travel advice for people planning a visit to Aruba.")
      edition = FactoryGirl.create(:published_travel_advice_edition, country_slug: 'aruba',
                                  title: "Travel advice for Aruba", overview: "This is the travel advice for people planning a visit to Aruba.",
                                  change_description: "Some stuff changed",
                                  summary: "This is the summary\n------\n",
                                  alert_status: ["avoid_all_but_essential_travel_to_parts","avoid_all_travel_to_parts"])

      get '/foreign-travel-advice%2Faruba.json'
      assert last_response.ok?

      parsed_response = JSON.parse(last_response.body)

      assert_base_artefact_fields(parsed_response)
      assert_equal 'travel-advice', parsed_response["format"]
      assert_equal 'Travel advice for Aruba', parsed_response["title"]
    end

    describe "loading related links data" do

      it "should include related links from the foreign-travel-advice index page" do

        index_related_artefacts = [
          FactoryGirl.create(:artefact, slug: "related-artefact-1", name: "Pies", state: 'live'),
          FactoryGirl.create(:artefact, slug: "related-artefact-2", name: "Cake", state: 'live')
        ]

        travel_index_artefact = FactoryGirl.create(:artefact, :slug => 'foreign-travel-advice', :state => 'live', :need_id => '133',
                                       :owning_app => 'travel-advice-publisher', :rendering_app => 'frontend', related_artefacts: index_related_artefacts)


        aruba_related_artefacts = [
          FactoryGirl.create(:artefact, slug: "related-artefact-3", name: "Pasties", state: 'live'),
          FactoryGirl.create(:artefact, slug: "related-artefact-4", name: "Sausages", state: 'live')
        ]
        aruba_artefact = FactoryGirl.create(:artefact, slug: 'foreign-travel-advice/aruba', state: 'live',
                                      kind: 'travel-advice', owning_app: 'travel-advice-publisher', related_artefacts: aruba_related_artefacts)

        aruba_edition = FactoryGirl.create(:published_travel_advice_edition, country_slug: 'aruba')


        get '/foreign-travel-advice/aruba.json'
        assert last_response.ok?

        parsed_response = JSON.parse(last_response.body)

        assert_equal 4, parsed_response["related"].length

      end

      it "should not include links that are drafts" do
        index_related_artefacts = [
          FactoryGirl.create(:artefact, slug: "related-artefact-1", name: "Pies", state: 'live'),
          FactoryGirl.create(:artefact, slug: "related-artefact-2", name: "Cake", state: 'live'),
          FactoryGirl.create(:artefact, slug: "related-artefact-3", name: "Burgers", state: 'draft')
        ]

        travel_index_artefact = FactoryGirl.create(:artefact, :slug => 'foreign-travel-advice', :state => 'live', :need_id => '133',
                                       :owning_app => 'travel-advice-publisher', :rendering_app => 'frontend', related_artefacts: index_related_artefacts)


        aruba_related_artefacts = [
          FactoryGirl.create(:artefact, slug: "related-artefact-4", name: "Pasties", state: 'live'),
          FactoryGirl.create(:artefact, slug: "related-artefact-5", name: "Sausages", state: 'live'),
          FactoryGirl.create(:artefact, slug: "related-artefact-6", name: "Burritos", state: 'draft')
        ]
        aruba_artefact = FactoryGirl.create(:artefact, slug: 'foreign-travel-advice/aruba', state: 'live',
                                      kind: 'travel-advice', owning_app: 'travel-advice-publisher', related_artefacts: aruba_related_artefacts)

        aruba_edition = FactoryGirl.create(:published_travel_advice_edition, country_slug: 'aruba')


        get '/foreign-travel-advice/aruba.json'
        assert last_response.ok?

        parsed_response = JSON.parse(last_response.body)

        assert_equal 4, parsed_response["related"].length

      end


      it "should not duplicate related links if they are on both the home page and the country page" do
        shared_artefact = FactoryGirl.create(:artefact, slug: "related-artefact-1", name: "Pies", state: "live")
        index_related_artefacts = [
          shared_artefact,
          FactoryGirl.create(:artefact, slug: "related-artefact-2", name: "Cake", state: 'live')
        ]

        travel_index_artefact = FactoryGirl.create(:artefact, :slug => 'foreign-travel-advice', :state => 'live', :need_id => '133',
                                       :owning_app => 'travel-advice-publisher', :rendering_app => 'frontend', related_artefacts: index_related_artefacts)
        aruba_related_artefacts = [
          shared_artefact,
          FactoryGirl.create(:artefact, slug: "related-artefact-3", name: "Sausages", state: 'live')
        ]
        aruba_artefact = FactoryGirl.create(:artefact, slug: 'foreign-travel-advice/aruba', state: 'live',
                                      kind: 'travel-advice', owning_app: 'travel-advice-publisher', related_artefacts: aruba_related_artefacts)

        aruba_edition = FactoryGirl.create(:published_travel_advice_edition, country_slug: 'aruba')


        get '/foreign-travel-advice/aruba.json'
        assert last_response.ok?

        parsed_response = JSON.parse(last_response.body)

        related_links = parsed_response["related"]

        assert_equal ["Pies", "Sausages", "Cake"], related_links.map {|l| l["title"] }
      end

    end

    describe "loading assets from asset-manager" do
      it "should include image and document details if present" do
        artefact = FactoryGirl.create(:artefact, slug: 'foreign-travel-advice/aruba', state: 'live',
                                      kind: 'travel-advice', owning_app: 'travel-advice-publisher')
        edition = FactoryGirl.create(:published_travel_advice_edition, country_slug: 'aruba',
                                     :image_id => "512c9019686c82191d000001",
                                     :document_id => "512c9019686c82191d000002")

        asset_manager_has_an_asset("512c9019686c82191d000001", {
          "id" => "https://asset-manager.production.alphagov.co.uk/assets/512c9019686c82191d000001",
          "name" => "darth-on-a-cat.jpg",
          "content_type" => "image/jpeg",
          "file_url" => "https://assets.digital.cabinet-office.gov.uk/media/512c9019686c82191d000001/darth-on-a-cat.jpg",
          "state" => "clean",
        })
        asset_manager_has_an_asset("512c9019686c82191d000002", {
          "id" => "https://asset-manager.production.alphagov.co.uk/assets/512c9019686c82191d000002",
          "name" => "cookie-monster.pdf",
          "content_type" => "application/pdf",
          "file_url" => "https://assets.digital.cabinet-office.gov.uk/media/512c9019686c82191d000002/cookie-monster.pdf",
          "state" => "clean",
        })

        get '/foreign-travel-advice/aruba.json'
        assert last_response.ok?

        parsed_response = JSON.parse(last_response.body)
        assert_base_artefact_fields(parsed_response)

        image_details = parsed_response["details"]["image"]
        assert_equal "https://assets.digital.cabinet-office.gov.uk/media/512c9019686c82191d000001/darth-on-a-cat.jpg", image_details["web_url"]
        assert_equal "image/jpeg", image_details["content_type"]

        document_details = parsed_response["details"]["document"]
        assert_equal "https://assets.digital.cabinet-office.gov.uk/media/512c9019686c82191d000002/cookie-monster.pdf", document_details["web_url"]
        assert_equal "application/pdf", document_details["content_type"]
      end

      it "should not include details if asset-manager returns 404 for the asset" do
        artefact = FactoryGirl.create(:artefact, slug: 'foreign-travel-advice/aruba', state: 'live',
                                      kind: 'travel-advice', owning_app: 'travel-advice-publisher')
        edition = FactoryGirl.create(:published_travel_advice_edition, country_slug: 'aruba',
                                     :image_id => "512c9019686c82191d000001",
                                     :document_id => "512c9019686c82191d000002")

        asset_manager_does_not_have_an_asset("512c9019686c82191d000001")
        asset_manager_has_an_asset("512c9019686c82191d000002", {
          "id" => "https://asset-manager.production.alphagov.co.uk/assets/512c9019686c82191d000002",
          "name" => "cookie-monster.pdf",
          "content_type" => "application/pdf",
          "file_url" => "https://assets.digital.cabinet-office.gov.uk/media/512c9019686c82191d000002/cookie-monster.pdf",
          "state" => "clean",
        })

        get '/foreign-travel-advice/aruba.json'
        assert last_response.ok?

        parsed_response = JSON.parse(last_response.body)
        assert_base_artefact_fields(parsed_response)

        refute parsed_response["details"].has_key?("image")

        document_details = parsed_response["details"]["document"]
        assert_equal "https://assets.digital.cabinet-office.gov.uk/media/512c9019686c82191d000002/cookie-monster.pdf", document_details["web_url"]
      end

      it "should not include details if the asset isn't marked as clean" do
        artefact = FactoryGirl.create(:artefact, slug: 'foreign-travel-advice/aruba', state: 'live',
                                      kind: 'travel-advice', owning_app: 'travel-advice-publisher')
        edition = FactoryGirl.create(:published_travel_advice_edition, country_slug: 'aruba',
                                     :image_id => "512c9019686c82191d000001",
                                     :document_id => "512c9019686c82191d000002")

        asset_manager_has_an_asset("512c9019686c82191d000001", {
          "id" => "https://asset-manager.production.alphagov.co.uk/assets/512c9019686c82191d000001",
          "name" => "darth-on-a-cat.jpg",
          "content_type" => "image/jpeg",
          "file_url" => "https://assets.digital.cabinet-office.gov.uk/media/512c9019686c82191d000001/darth-on-a-cat.jpg",
          "state" => "unscanned",
        })
        asset_manager_has_an_asset("512c9019686c82191d000002", {
          "id" => "https://asset-manager.production.alphagov.co.uk/assets/512c9019686c82191d000002",
          "name" => "cookie-monster.pdf",
          "content_type" => "application/pdf",
          "file_url" => "https://assets.digital.cabinet-office.gov.uk/media/512c9019686c82191d000002/cookie-monster.pdf",
          "state" => "infected",
        })

        get '/foreign-travel-advice/aruba.json'
        assert last_response.ok?

        parsed_response = JSON.parse(last_response.body)
        assert_base_artefact_fields(parsed_response)

        refute parsed_response["details"].has_key?("image")
        refute parsed_response["details"].has_key?("document")
      end

      it "should authenticate with asset-manager if configured" do
        ::API_CLIENT_CREDENTIALS = {:bearer_token => "foobar"}
        GovUkContentApi.instance_variable_set('@asset_manager_api', nil)

        artefact = FactoryGirl.create(:artefact, slug: 'foreign-travel-advice/aruba', state: 'live',
                                      kind: 'travel-advice', owning_app: 'travel-advice-publisher')
        edition = FactoryGirl.create(:published_travel_advice_edition, country_slug: 'aruba',
                                     :image_id => "512c9019686c82191d000003")

        asset_manager_has_an_asset("512c9019686c82191d000003", {
          "id" => "https://asset-manager.production.alphagov.co.uk/assets/512c9019686c82191d000003",
          "name" => "darth-on-a-cat.jpg",
          "content_type" => "image/jpeg",
          "file_url" => "https://assets.digital.cabinet-office.gov.uk/media/512c9019686c82191d000003/darth-on-a-cat.jpg",
          "state" => "clean",
        })

        get '/foreign-travel-advice/aruba.json'
        assert last_response.ok?

        assert_requested(:get, %r{\A#{ASSET_MANAGER_ENDPOINT}}, :headers => {"Authorization" => "Bearer foobar"})
      end

      it "should not include details if asset manager is unavailable or returns an error" do
        artefact = FactoryGirl.create(:artefact, slug: 'foreign-travel-advice/aruba', state: 'live',
                                      kind: 'travel-advice', owning_app: 'travel-advice-publisher')
        edition = FactoryGirl.create(:published_travel_advice_edition, country_slug: 'aruba',
                                     :image_id => "512c9019686c82191d000001",
                                     :document_id => "512c9019686c82191d000002")

        stub_request(:get, "http://asset-manager.dev.gov.uk/assets/512c9019686c82191d000001").to_timeout
        stub_request(:get, "http://asset-manager.dev.gov.uk/assets/512c9019686c82191d000002").to_return(:body => "Error", :status => 500)

        get '/foreign-travel-advice%2Faruba.json'
        assert last_response.ok?

        parsed_response = JSON.parse(last_response.body)

        refute parsed_response["details"].has_key?("image")
        refute parsed_response["details"].has_key?("document")
      end

      after do
        if Object.const_defined?(:API_CLIENT_CREDENTIALS)
          Object.instance_eval { remove_const(:API_CLIENT_CREDENTIALS) }
        end
      end
    end

    it "should return draft data when authenticated" do
      artefact = FactoryGirl.create(:artefact, slug: 'foreign-travel-advice/aruba', state: 'live',
                                    kind: 'travel-advice', owning_app: 'travel-advice-publisher', name: "Aruba travel advice",
                                    description: "This is the travel advice for people planning a visit to Aruba.")
      edition = FactoryGirl.build(:travel_advice_edition, country_slug: 'aruba',
                                  title: "Travel advice for Aruba", overview: "This is the travel advice for people planning a visit to Aruba.",
                                  summary: "This is the summary\n------\n")
      edition.parts.build(title: "Part One", slug: 'part-one', body: "This is part one\n------\n")
      edition.save!

      Warden::Proxy.any_instance.expects(:authenticate?).returns(true)
      Warden::Proxy.any_instance.expects(:user).returns(ReadOnlyUser.new("permissions" => ["access_unpublished"]))

      get '/foreign-travel-advice/aruba.json?edition=1'
      assert last_response.ok?

      parsed_response = JSON.parse(last_response.body)

      assert_base_artefact_fields(parsed_response)
      assert_equal 'travel-advice', parsed_response["format"]
      assert_equal 'Travel advice for Aruba', parsed_response["title"]
      assert_equal edition.updated_at.xmlschema, parsed_response["updated_at"]

      details = parsed_response["details"]
      assert_equal 'This is the travel advice for people planning a visit to Aruba.', details['description']
      assert_equal '<h2>This is the summary</h2>', details['summary'].strip

      # Country details
      assert_equal({"name" => "Aruba", "slug" => "aruba"}, details["country"])

      # Parts
      parts = details["parts"]
      assert_equal 1, parts.length

      assert_equal "Part One", parts[0]["title"]
      assert_equal "part-one", parts[0]["slug"]
      assert_equal "<h2>This is part one</h2>", parts[0]["body"].strip
    end

    it "should 404 for a country with a draft edition only" do
      artefact = FactoryGirl.create(:artefact, slug: 'foreign-travel-advice/aruba', state: 'live',
                                    kind: 'travel-advice', owning_app: 'travel-advice-publisher', name: "Aruba travel advice",
                                    description: "This is the travel advice for people planning a visit to Aruba.")
      edition = FactoryGirl.build(:travel_advice_edition, country_slug: 'aruba',
                                  title: "Travel advice for Aruba", overview: "This is the travel advice for people planning a visit to Aruba.",
                                  summary: "This is the summary\n------\n")
      edition.parts.build(title: "Part One", slug: 'part-one', body: "This is part one\n------\n")
      edition.save!

      get '/foreign-travel-advice/aruba.json'
      assert last_response.not_found?
    end

    it "should 404 for a country with no published advice" do
      get '/foreign-travel-advice/angola.json'
      assert last_response.not_found?
    end

    it "should 404 for a non-existent country" do
      get '/foreign-travel-advice/wibble.json'
      assert last_response.not_found?
    end
  end
end
