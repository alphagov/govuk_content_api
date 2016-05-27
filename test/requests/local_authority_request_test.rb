require "test_helper"

class LocalAuthorityRequestTest < GovUkContentApiTest
  it "should return 410 if no name or snac code is provided" do
    get "/local_authorities.json"
    assert_equal 410, last_response.status
    assert_status_field "gone", last_response
  end

  it "should return 410 if a snac code is provided" do
    get "/local_authorities/gobble_de_gook.json"
    assert_equal 410, last_response.status
    assert_status_field "gone", last_response
  end
end
