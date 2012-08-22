require 'test_helper'

class FormatsRequestTest < GovUkContentApiTest

	def setup
		super
		@tag1 = FactoryGirl.create(:tag, tag_id: 'crime')
		@tag2 = FactoryGirl.create(:tag, tag_id: 'crime/batman')
	end

	def _assert_base_response_info(parsed_response)
		assert_equal 'ok', parsed_response["response"]["status"]
		assert parsed_response["response"]["result"].has_key?('title')
		assert parsed_response["response"]["result"].has_key?('id')
	end

	def _assert_has_expected_fields(parsed_response, fields)
		fields.each do |field|
			assert parsed_response.has_key?(field), 'Field #{field} is MISSING'
		end
	end

	def test_answer_edition
		artefact = FactoryGirl.create(:artefact, slug: 'batman', owning_app: 'publisher', sections: [@tag1.tag_id])
		answer = FactoryGirl.create(:edition, slug: artefact.slug, body: 'Important batman information', panopticon_id: artefact.id, state: 'published')

		get '/batman.json'
		parsed_response = JSON.parse(last_response.body)

		assert last_response.ok?
		_assert_base_response_info(parsed_response)

		fields = parsed_response["response"]["result"]["fields"]

		expected_fields = ['tag_ids', 'alternative_title', 'overview', 'body', 'section']

		_assert_has_expected_fields(fields, expected_fields)		
		assert_equal "Important batman information", fields["body"]
	end

	def test_business_support_edition
		artefact = FactoryGirl.create(:artefact, slug: 'batman', owning_app: 'publisher', sections: [@tag1.tag_id])
		business_support = FactoryGirl.create(:business_support_edition, slug: artefact.slug, 
																short_description: "No policeman's going to give the Batmobile a ticket", min_value: 100, 
																max_value: 1000, panopticon_id: artefact.id, state: 'published')
		business_support.parts[0].body = "Lalalala"
		business_support.save!

		get '/batman.json'
		parsed_response = JSON.parse(last_response.body)

		assert last_response.ok?
		_assert_base_response_info(parsed_response)

		fields = parsed_response["response"]["result"]["fields"]
		expected_fields = ['tag_ids', 'alternative_title', 'overview', 'section', 
												'short_description', 'min_value', 'max_value', 'parts']

		_assert_has_expected_fields(fields, expected_fields)
		assert_false fields.has_key?('body')
		assert_equal "Lalalala", fields['parts'][0]["body"]

	end
end