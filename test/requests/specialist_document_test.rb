require_relative '../test_helper'
require 'gds_api/test_helpers/asset_manager'

class SpecialistDocumentTest < GovUkContentApiTest
  def parsed_response
    @parsed_response ||= JSON.parse(last_response.body)
  end

  describe "loading a published specialist document" do
    def build_rendered_specialist_document!(document_attributes = {})

      document_defaults = {
        slug: "mhra-drug-alerts/private-healthcare-investigation",
        title: "Private Healthcare Investigation",
        summary: "This is the summary",
        body: "<p>This is the body</p>",
        opened_date: Date.parse("2013-03-21"),
        closed_date: nil,
        case_type: "market-investigation",
        case_type_label: "Market investigation",
        case_state: "open",
        case_state_label: "Open",
        market_sector: "healthcare",
        market_sector_label: "Healthcare",
        outcome_type: "referred",
        outcome_type_label: "Referred",
        headers: [],
      }

      document_attributes = document_defaults.merge(document_attributes)

      @artefact = FactoryGirl.create(:artefact,
        slug: "mhra-drug-alerts/private-healthcare-investigation",
        state: "live",
        kind: "specialist-document",
        owning_app: "specialist-publisher",
        name: "Private Healthcare Investigation"
      )

      @document = FactoryGirl.create(:rendered_specialist_document, document_attributes)
    end

    it "should return a successful response" do
      build_rendered_specialist_document!
      get '/mhra-drug-alerts/private-healthcare-investigation.json'
      assert last_response.ok?
    end

    it "should return json containing the rendered document" do
      build_rendered_specialist_document!
      get '/mhra-drug-alerts/private-healthcare-investigation.json'

      assert_base_artefact_fields(parsed_response)
      assert_equal 'specialist-document', parsed_response["format"]
      assert_equal 'Private Healthcare Investigation', parsed_response["title"]
      assert_equal 'This is the summary', parsed_response["details"]["summary"]
      assert_equal '2013-03-21', parsed_response["details"]["opened_date"]
      assert_equal nil, parsed_response["details"]["closed_date"]
      assert_equal "market-investigation", parsed_response["details"]["case_type"]
      assert_equal "open", parsed_response["details"]["case_state"]
      assert_equal "healthcare", parsed_response["details"]["market_sector"]
      assert_equal "referred", parsed_response["details"]["outcome_type"]
    end

    it "should include facet labels in the json" do
      build_rendered_specialist_document!
      get '/mhra-drug-alerts/private-healthcare-investigation.json'

      assert_equal "Market investigation", parsed_response["details"]["case_type_label"]
      assert_equal "Open", parsed_response["details"]["case_state_label"]
      assert_equal "Healthcare", parsed_response["details"]["market_sector_label"]
      assert_equal "Referred", parsed_response["details"]["outcome_type_label"]
    end

    it "should include the body of the rendered document" do
      html_body = %Q{<h2 id="heading">Heading</h2>\n}

      build_rendered_specialist_document!(body: html_body)

      get "/#{@artefact.slug}.json"

      assert_equal html_body, parsed_response['details']['body']
    end

    it "should provide hierarchical headers for the document body" do
      example_headers = [
        {
          "text" => "Heading",
          "id" => "heading",
          "level" => 2,
          "headers" => [
            {
              "text" => "Subheading",
              "id" => "subheading",
              "level" => 3,
              "headers" => []
            }
          ]
        }
      ]

      build_rendered_specialist_document!(headers: example_headers)

      get "#{@artefact.slug}.json"

      if last_response.ok?
        actual_headers = JSON.parse(last_response.body).fetch("details").fetch("headers")

        assert_equal example_headers, actual_headers
      else
        fail "RESPONSE: #{last_response.status}" + last_response.body
      end
    end
  end

  describe "artefact but no rendered specialist document" do
    before do
      @artefact = FactoryGirl.create(:artefact,
        slug: "mhra-drug-alerts/private-healthcare-investigation",
        state: "live",
        kind: "specialist-document",
        owning_app: "specialist-publisher",
        name: "Private Healthcare Investigation"
      )
    end

    it "should return 404 response" do
      get '/mhra-drug-alerts/private-healthcare-investigation.json'
      assert last_response.not_found?
    end
  end
end
