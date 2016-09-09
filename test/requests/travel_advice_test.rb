require_relative '../test_helper'
require 'gds_api/test_helpers/asset_manager'

class TravelAdviceTest < GovUkContentApiTest
  include GdsApi::TestHelpers::AssetManager

  describe "loading the travel-advice index artefact" do
    before do
      @artefact = FactoryGirl.create(:artefact, slug: 'foreign-travel-advice', state: 'live', need_ids: ['100003'],
                                     owning_app: 'travel-advice-publisher', rendering_app: 'frontend',
                                     name: 'Foreign travel advice', description: 'Oh I do want to live beside the seaside!')
    end

    it "should return the normal artefact fields" do
      get '/foreign-travel-advice.json'
      assert last_response.ok?

      parsed_response = JSON.parse(last_response.body)

      assert_base_artefact_fields(parsed_response)
      assert_equal 'Foreign travel advice', parsed_response['title']

      details = parsed_response["details"]
      expected_fields = %w(description need_ids)
      assert_has_expected_fields(details, expected_fields)
      assert_equal 'Oh I do want to live beside the seaside!', details['description']
    end

    it "should include an alphabetical list of countries with published editions" do
      edition1 = FactoryGirl.create(:published_travel_advice_edition, country_slug: 'afghanistan',
                                    change_description: "Some stuff changed", published_at: 2.days.ago, synonyms: %w(bar foo))
      FactoryGirl.create(:published_travel_advice_edition, country_slug: 'angola')
      FactoryGirl.create(:published_travel_advice_edition, country_slug: 'andorra')

      get '/foreign-travel-advice.json'
      assert last_response.ok?

      parsed_response = JSON.parse(last_response.body)

      countries = parsed_response['details']['countries']

      assert_equal 3, countries.length

      assert_equal %w(Afghanistan Andorra Angola), countries.map { |c| c["name"] }

      first = countries.first
      assert_equal "Afghanistan", first["name"]
      assert_equal "afghanistan", first["identifier"]
      assert_equal "http://example.org/foreign-travel-advice%2Fafghanistan.json", first["id"]
      assert_equal "https://www.gov.uk/foreign-travel-advice/afghanistan", first["web_url"]
      assert_equal edition1.published_at.xmlschema, first["updated_at"]
      assert_equal "Some stuff changed", first["change_description"]
      assert_equal %w(bar foo), first["synonyms"]
    end

    it "should not include countries without published editions" do
      FactoryGirl.create(:archived_travel_advice_edition, country_slug: 'afghanistan')
      FactoryGirl.create(:draft_travel_advice_edition, country_slug: 'angola')
      FactoryGirl.create(:published_travel_advice_edition, country_slug: 'andorra')

      get '/foreign-travel-advice.json'
      assert last_response.ok?

      parsed_response = JSON.parse(last_response.body)

      countries = parsed_response['details']['countries']
      assert_equal 1, countries.length
      assert_equal ["Andorra"], countries.map { |c| c["name"] }
    end

    it "should not include published editions for a non-existent country" do
      FactoryGirl.create(:published_travel_advice_edition, country_slug: 'afghanistan',
                                  alert_status: %w(avoid_all_but_essential_travel_to_parts avoid_all_travel_to_parts))
      FactoryGirl.create(:published_travel_advice_edition, country_slug: 'angola')
      FactoryGirl.create(:published_travel_advice_edition, country_slug: 'narnia')

      get '/foreign-travel-advice.json'
      assert last_response.ok?

      parsed_response = JSON.parse(last_response.body)

      countries = parsed_response['details']['countries']
      assert_equal 2, countries.length
      assert_equal %w(Afghanistan Angola), countries.map { |c| c["name"] }
    end
  end
end
