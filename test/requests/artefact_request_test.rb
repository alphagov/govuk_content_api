require 'test_helper'

class ArtefactRequestTest < GovUkContentApiTest

  def bearer_token_for_user_with_permission
    { 'HTTP_AUTHORIZATION' => 'Bearer xyz_has_permission_xyz' }
  end

  def bearer_token_for_user_without_permission
    { 'HTTP_AUTHORIZATION' => 'Bearer xyz_does_not_have_permission_xyz' }
  end

  it "should return 410 for any artefact" do
    get '/artefact.json'
    assert_equal 410, last_response.status
    assert_status_field "gone", last_response
  end
end
