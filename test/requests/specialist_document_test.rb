require_relative '../test_helper'
require 'gds_api/test_helpers/asset_manager'

class SpecialistDocumentTest < GovUkContentApiTest
  def parsed_response
    @parsed_response ||= JSON.parse(last_response.body)
  end

  describe 'loading a published manual' do
    def build_manual!(manual_attributes = {})

      document_defaults = {
        slug: 'guidance/immigration-rules/family-members',
        title: 'Immigration rules',
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
    end
  end
end
