require_relative '../test_helper'

class TravelAdviceTest < GovUkContentApiTest

  describe "loading a list of travel advice countries" do
    it "should return an alphabetical list of countries" do
      get '/travel-advice.json'
      assert last_response.ok?

      parsed_response = JSON.parse(last_response.body)

      assert_equal 14, parsed_response["total"]
      assert_equal 14, parsed_response["results"].length

      assert_equal "Afghanistan", parsed_response["results"].first["name"]
      assert_equal "afghanistan", parsed_response["results"].first["identifier"]
      assert_equal "http://example.org/travel-advice%2Fafghanistan.json", parsed_response["results"].first["id"]
      assert_equal "https://www.gov.uk/travel-advice/afghanistan", parsed_response["results"].first["web_url"]
    end

    it "should attach an edition to a country where a published edition is present" do
      edition = FactoryGirl.create(:published_travel_advice_edition, country_slug: 'afghanistan',
                                  alert_status: ["avoid_all_but_essential_travel_to_parts","avoid_all_travel_to_parts"])
      get '/travel-advice.json'
      assert last_response.ok?

      parsed_response = JSON.parse(last_response.body)

      assert_equal "afghanistan", parsed_response["results"].first["identifier"]
      assert_equal edition.updated_at, parsed_response["results"].first["updated_at"]
      assert_equal ["avoid_all_but_essential_travel_to_parts","avoid_all_travel_to_parts"], parsed_response["results"].first["alert_status"]
    end

    it "should not attach an edition to a country where a published edition is not present" do
      edition = FactoryGirl.create(:draft_travel_advice_edition, country_slug: 'afghanistan',
                                  alert_status: ["avoid_all_but_essential_travel_to_parts","avoid_all_travel_to_parts"])
      get '/travel-advice.json'
      assert last_response.ok?

      parsed_response = JSON.parse(last_response.body)

      assert_equal "afghanistan", parsed_response["results"].first["identifier"]
      assert_equal nil, parsed_response["results"].first["alert_status"]
      assert_equal nil, parsed_response["results"].first["updated_at"]
    end
  end

  describe "loading data for a travel advice country page" do

    it "should return details for a country with published advice" do
      artefact = FactoryGirl.create(:artefact, slug: 'travel-advice/aruba', state: 'live',
                                    kind: 'travel-advice', owning_app: 'travel-advice-publisher', name: "Aruba travel advice",
                                    description: "This is the travel advice for people planning a visit to Aruba.")
      edition = FactoryGirl.build(:travel_advice_edition, country_slug: 'aruba',
                                  title: "Travel advice for Aruba", overview: "This is the travel advice for people planning a visit to Aruba.",
                                  summary: "This is the summary\n------\n",
                                  alert_status: ["avoid_all_but_essential_travel_to_parts","avoid_all_travel_to_parts"])
      edition.parts.build(title: "Part One", slug: 'part-one', body: "This is part one\n------\n")
      edition.parts.build(title: "Part Two", slug: 'part-two', body: "And some more stuff in part 2.")
      edition.save!
      edition.publish!

      get '/travel-advice%2Faruba.json'
      assert last_response.ok?

      parsed_response = JSON.parse(last_response.body)

      assert_base_artefact_fields(parsed_response)
      assert_equal 'travel-advice', parsed_response["format"]
      assert_equal 'Travel advice for Aruba', parsed_response["title"]

      details = parsed_response["details"]
      assert_equal 'This is the travel advice for people planning a visit to Aruba.', details['description']
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

    it "should 404 for a country with no published advice" do
      get '/travel-advice%2Fangola.json'
      assert last_response.not_found?
    end

    it "should 404 for a non-existent country" do
      get '/travel-advice%2Fwibble.json'
      assert last_response.not_found?
    end
  end
end
