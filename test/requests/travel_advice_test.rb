require_relative '../test_helper'

class TravelAdviceTest < GovUkContentApiTest

  describe "loading data for a travel advice country page" do

    it "should return details for a country with published advice" do
      artefact = FactoryGirl.create(:artefact, slug: 'travel-advice/aruba', state: 'live',
                                    kind: 'travel-advice', owning_app: 'travel-advice-publisher', name: "Aruba travel advice",
                                    description: "This is the travel advice for people planning a visit to Aruba.")
      edition = FactoryGirl.build(:travel_advice_edition, country_slug: 'aruba', state: 'published',
                                  title: "Travel advice for Aruba", overview: "This is the travel advice for people planning a visit to Aruba.")
      edition.parts.build(title: "Summary", slug: 'summary', body: "This is the summary\n------\n")
      edition.parts.build(title: "Part Two", slug: 'part-two', body: "And some more stuff in part 2.")
      edition.save!

      get '/travel-advice%2Faruba.json'
      assert last_response.ok?

      parsed_response = JSON.parse(last_response.body)

      assert_base_artefact_fields(parsed_response)
      assert_equal 'travel-advice', parsed_response["format"]
      assert_equal 'Travel advice for Aruba', parsed_response["title"]

      details = parsed_response["details"]
      assert_equal 'This is the travel advice for people planning a visit to Aruba.', details['description']
      
      # Country details
      assert_equal({"name" => "Aruba", "slug" => "aruba"}, details["country"])

      # Parts
      parts = details["parts"]
      assert_equal 2, parts.length

      assert_equal "Summary", parts[0]["title"]
      assert_equal "summary", parts[0]["slug"]
      assert_equal "<h2>This is the summary</h2>", parts[0]["body"].strip

      assert_equal "Part Two", parts[1]["title"]
      assert_equal "part-two", parts[1]["slug"]
      assert_equal "<p>And some more stuff in part 2.</p>", parts[1]["body"].strip
    end

    it "should return basic country details for a country with no published advice" do

      get '/travel-advice%2Fangola.json'
      assert last_response.ok?
      
      parsed_response = JSON.parse(last_response.body)

      assert_base_artefact_fields(parsed_response)
      assert_equal 'travel-advice', parsed_response["format"]
      assert_equal "Angola", parsed_response["title"]

      details = parsed_response["details"]

      assert_equal({"name" => "Angola", "slug" => "angola"}, details["country"])
    end

    it "should 404 for a non-existent country" do
      get '/travel-advice%2Fwibble.json'
      assert last_response.not_found?
    end
  end
end
