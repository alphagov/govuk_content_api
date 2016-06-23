require 'test_helper'

class CompletedTransactionArtefactRequestTest < GovUkContentApiTest
  it "should contain presentation toggles to indicate what promotions should be displayed" do
    artefact = FactoryGirl.create(:artefact, state: 'live')
    edition = FactoryGirl.create(:completed_transaction_edition, panopticon_id: artefact.id, state: 'published')
    organ_donor_registration_url = "https://www.organdonation.nhs.uk/how_to_become_a_donor/registration/consent.asp?campaign="

    get "/#{artefact.slug}.json"
    assert_equal 200, last_response.status
    response = JSON.parse(last_response.body)
    refute response["details"]["presentation_toggles"]["promotion_choice"]["choice"] == "organ_donor"

    edition.promotion_choice = "organ_donor"
    edition.promotion_choice_url = organ_donor_registration_url
    edition.save(validate: false)

    get "/#{artefact.slug}.json"
    assert_equal 200, last_response.status
    response = JSON.parse(last_response.body)
    assert response["details"]["presentation_toggles"]["promotion_choice"]["choice"] == "organ_donor"
    assert_equal organ_donor_registration_url, response["details"]["presentation_toggles"]["promotion_choice"]["url"]
  end
end
