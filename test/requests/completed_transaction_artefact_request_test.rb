require 'test_helper'

class CompletedTransactionArtefactRequestTest < GovUkContentApiTest
  it "should contain presentation toggles to indicate what promotions should be displayed" do
    artefact = FactoryGirl.create(:artefact, state: 'live')
    edition = FactoryGirl.create(:completed_transaction_edition, panopticon_id: artefact.id, state: 'published')
    organ_donor_registration_url = "https://www.organdonation.nhs.uk/how_to_become_a_donor/registration/consent.asp?campaign="

    get "/#{artefact.slug}.json"
    assert_equal 200, last_response.status
    response = JSON.parse(last_response.body)
    refute response["details"]["presentation_toggles"]["organ_donor_registration"]["promote_organ_donor_registration"]

    edition.promote_organ_donor_registration = true
    edition.organ_donor_registration_url = organ_donor_registration_url
    edition.save(validate: false)

    get "/#{artefact.slug}.json"
    assert_equal 200, last_response.status
    response = JSON.parse(last_response.body)
    assert response["details"]["presentation_toggles"]["organ_donor_registration"]["promote_organ_donor_registration"]
    assert_equal organ_donor_registration_url, response["details"]["presentation_toggles"]["organ_donor_registration"]["organ_donor_registration_url"]
  end
end
