require_relative '../test_helper'

class ArtefactsTaggedToBrowsePagesTest < GovUkContentApiTest
  describe 'GET /whitehall-artefacts-tagged-to-mainstream-browse-pages.json' do
    it 'returns whitehall artefacts tagged to mainstream browse pages' do
      FactoryGirl.create(:live_tag, tag_id: 'food', tag_type: 'section')
      FactoryGirl.create(:live_tag, tag_id: 'yo-food', tag_type: 'specialist_sector')
      FactoryGirl.create(:live_tag, tag_id: 'food/pastries', parent_id: 'food', tag_type: 'section')
      FactoryGirl.create(:whitehall_live_artefact, slug: 'government/food-is-good', section_ids: %w[food/pastries], specialist_sector_ids: %w[yo-food])

      get '/whitehall-artefacts-tagged-to-mainstream-browse-pages.json'

      assert_equal [{ 'artefact_slug' => 'government/food-is-good', 'mainstream_browse_page_slugs' => ['food/pastries'] }],
        parsed_response
    end

    it 'does not return artefacts tagged to mainstream browse pages from other apps' do
      FactoryGirl.create(:live_tag, tag_id: 'food', tag_type: 'section')
      FactoryGirl.create(:artefact, :live, owning_app: 'trade-tariff', section_ids: %w[food])

      get '/whitehall-artefacts-tagged-to-mainstream-browse-pages.json'

      assert_equal [], parsed_response
    end
  end

  def parsed_response
    @parsed_response ||= JSON.parse(last_response.body)
  end
end
