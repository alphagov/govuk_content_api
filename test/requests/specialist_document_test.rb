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
        details: {
          "opened_date" => "2013-03-21",
          "case_type" => "market-investigation",
          "case_type_label" => "Market investigation",
        }
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
      assert_equal "market-investigation", parsed_response["details"]["case_type"]
    end

    it "should include facet labels in the json" do
      build_rendered_specialist_document!
      get '/mhra-drug-alerts/private-healthcare-investigation.json'

      assert_equal "Market investigation", parsed_response["details"]["case_type_label"]
    end

    it "should include the body of the rendered document" do
      html_body = %Q{<h2 id="heading">Heading</h2>\n}

      build_rendered_specialist_document!(body: html_body)

      get "/#{@artefact.slug}.json"

      assert_equal html_body, parsed_response['details']['body']
    end
  end

  describe 'loading a published manual' do
    def build_manual!(manual_attributes = {})

      document_defaults = {
        slug: 'guidance/immigration-rules/family-members',
        title: 'Immigration rules',
        summary: 'This is the summary',
        section_groups: section_groups,
      }

      manual_attributes = document_defaults.merge(manual_attributes)

      @slug = 'guidance/immigration-rules/family-members'

      FactoryGirl.create(:artefact,
        slug: @slug,
        state: 'live',
        kind: 'manual',
        owning_app: 'specialist-publisher',
        name: 'Immigration rules',
      )

      FactoryGirl.create(:rendered_manual, manual_attributes)
    end

    def section_groups
      [
        {
          "title" => "Contents",
          "sections" => [
            {
              "slug" => 'guidance/immigration-rules/section-1',
              "title" => 'Section 1',
              "summary" => 'Summary section 1',
            },
          ],
        },
      ]
    end

    it 'should return a successful response' do
      build_manual!
      get "/#{@slug}.json"

      assert last_response.ok?
    end

    it 'should return json containing the rendered document' do
      manual = build_manual!
      get "/#{@slug}.json"

      assert_base_artefact_fields(parsed_response)

      assert_equal 'manual', parsed_response["format"]
      assert_equal 'Immigration rules', parsed_response["title"]
      assert_equal 'This is the summary', parsed_response["details"]["summary"]
      assert_equal section_groups, parsed_response["details"]["section_groups"]
    end
  end

  describe 'loading a published manual section' do
    def build_rendered_specialist_document!(document_attributes = {})

      document_defaults = {
        slug: 'guidance/immigration-rules/family-members',
        title: 'Immigration rules part 8: family members',
        summary: 'This is the summary',
        body: '<p>This is the body</p>',
      }

      document_attributes = document_defaults.merge(document_attributes)

      @artefact = FactoryGirl.create(:artefact,
        slug: 'guidance/immigration-rules/family-members',
        state: 'live',
        kind: 'manual-section',
        owning_app: 'specialist-publisher',
        name: 'Immigration rules part 8: family members'
      )

      @document = FactoryGirl.create(:rendered_specialist_document, document_attributes)
    end

    it 'should return a successful response' do
      build_rendered_specialist_document!
      get "/#{@artefact.slug}.json"

      assert last_response.ok?
    end

    it 'should return json containing the rendered document' do
      build_rendered_specialist_document!
      get "/#{@artefact.slug}.json"

      assert_base_artefact_fields(parsed_response)
      assert_equal 'manual-section', parsed_response["format"]
      assert_equal 'Immigration rules part 8: family members', parsed_response["title"]
      assert_equal 'This is the summary', parsed_response["details"]["summary"]
    end

    it 'should include the body of the rendered document' do
      html_body = %Q{<h2 id="heading">Heading</h2>\n}

      build_rendered_specialist_document!(body: html_body)
      get "/#{@artefact.slug}.json"

      assert_equal html_body, parsed_response['details']['body']
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

  describe 'loading manual change history' do
    def build_change_history!
      @manual_slug = 'guidance/immigration-rules'
      @slug = "#{@manual_slug}/updates"

      @updates = [
        {
          "published_at" => "2014-01-01T08:45:00",
          "slug" => "#{@slug}/a-section",
          "title" => "Manual section",
          "change_note" => "Changed a thing",
        },
      ]

      FactoryGirl.create(:artefact,
        slug: @slug,
        state: 'live',
        kind: 'manual-change-history',
        owning_app: 'specialist-publisher',
        rendering_app: 'manuals-frontend',
        name: 'Immigration rules updates',
      )

      ManualChangeHistory.create!(
        slug: @slug,
        manual_slug: @manual_slug,
        updates: @updates,
      )
    end

    it 'should return a successful response' do
      build_change_history!
      get "/#{@slug}.json"

      assert last_response.ok?
    end

    it 'should return json containing the manual slug and updates' do
      build_change_history!
      get "/#{@slug}.json"

      assert_equal @updates, parsed_response["details"]["updates"]
      assert_equal @manual_slug, parsed_response["details"]["manual_slug"]
    end
  end
end
