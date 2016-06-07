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

  describe "setting cache-control headers" do
    it "should set long cache-control headers if no name or snac code is provided" do
      get "/local_authorities.json"
      assert_equal "public, max-age=#{1.hour.to_i}", last_response.headers["Cache-control"]
    end

    it "should set long cache-control headers for a snac lookup" do
      get "/local_authorities/00CT.json"
      assert_equal "public, max-age=#{1.hour.to_i}", last_response.headers["Cache-control"]
    end
  end
end
