require "test_helper"

class LocalAuthorityRequestTest < GovUkContentApiTest
  describe "local authorities index URL" do
    it "should return 410" do
      get "/local_authorities.json"
      assert_equal 410, last_response.status
      assert_status_field "gone", last_response
    end

    it "should set long cache-control headers" do
      get "/local_authorities.json"
      assert_equal "public, max-age=#{1.hour.to_i}", last_response.headers["Cache-control"]
    end
  end

  describe "local authorities with SNAC" do
    it "should return 410" do
      get "/local_authorities/gobble_de_gook.json"
      assert_equal 410, last_response.status
      assert_status_field "gone", last_response
    end

    it "should set long cache-control headers" do
      get "/local_authorities/00CT.json"
      assert_equal "public, max-age=#{1.hour.to_i}", last_response.headers["Cache-control"]
    end
  end
end
