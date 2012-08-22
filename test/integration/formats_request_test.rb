require 'test_helper'

class FormatsRequestTest < GovUkContentApiTest

	def setup
		super
		@tag1 = FactoryGirl.create(:tag, tag_id: 'crime')
		@tag2 = FactoryGirl.create(:tag, tag_id: 'crime/batman')
	end

	def test_answer_edition
		artefact = FactoryGirl.create(:artefact, slug: 'batman', owning_app: 'publisher')
		artefact.sections = [@tag1.tag_id]
		artefact.save!
		answer = FactoryGirl.create(:edition, slug: artefact.slug, body: 'Important batman information', panopticon_id: artefact.id, state: 'published')

		get '/batman.json'
		parsed_response = JSON.parse(last_response.body)

		assert last_response.ok?
		fields = parsed_response["response"]["result"]["fields"]

		assert fields.has_key?('tag_ids')
		assert fields.has_key?('alternative_title')
		
		assert_equal 'ok', parsed_response["response"]["status"]
		assert_equal "<p>Important batman information</p>\n", fields["body"]
	end
end