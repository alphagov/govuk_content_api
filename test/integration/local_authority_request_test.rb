require "test_helper"

class LocalAuthorityRequestTest < GovUkContentApiTest
  include URLHelpers

  def assert_status_field(expected, response)
    assert_equal expected, JSON.parse(response.body)["_response_info"]["status"]
  end

  should "return 404 if no snac code is provided" do
    get "/local_authorities/"
    assert last_response.not_found?
  end

  should "return 404 if no name or snac code is provided" do
    get "/local_authorities.json"
    assert last_response.not_found?
    assert_status_field "not found", last_response
  end

  should "return 404 if LocalAuthority with the provided snac code not found" do
    get "/local_authorities/gobble_de_gook.json"
    assert last_response.not_found?
    assert_status_field "not found", last_response
  end

  should "return an empty result set if LocalAuthority with the provided name not found" do
    get "/local_authorities.json?name=Somewhere%20over%20the%20rainbow"
    parsed_response = JSON.parse(last_response.body)

    assert last_response.ok?
    assert_status_field "ok", last_response
    assert_equal 0, parsed_response["total"]
    assert_equal true, parsed_response["results"].empty?
  end

  should "return a JSON formatted LocalAuthority when querying with a known snac code" do
    stub_authority = LocalAuthority.new(name: "Super Nova", snac: "supernova")
    LocalAuthority.stubs(:find_by_snac).with("supernova").returns(stub_authority)

    get "/local_authorities/supernova.json"
    parsed_response = JSON.parse(last_response.body)

    assert last_response.ok?
    assert_status_field "ok", last_response
    assert_equal "Super Nova", parsed_response["name"]
    assert_equal "supernova", parsed_response["snac_code"]
  end

  should "return a JSON formatted array of LocalAuthority objects when searching by name" do
    stub_authority = LocalAuthority.new(name: "Solihull Metropolitan Borough Council", snac: "00CT")
    LocalAuthority.stubs(:where).with(name: /^Solihull\ Metro/i).returns(stub_authority)

    get "/local_authorities.json?name=Solihull%20Metro"
    parsed_response = JSON.parse(last_response.body)

    assert last_response.ok?
    assert_status_field "ok", last_response
    assert_equal "Solihull Metropolitan Borough Council", parsed_response["results"][0]["name"]
    assert_equal "00CT", parsed_response["results"][0]["snac_code"]
  end

  should "return a JSON formatted array of LocalAuthority objects when searching by snac code" do
    stub_authority = LocalAuthority.new(name: "Solihull Metropolitan Borough Council", snac: "00CT")
    LocalAuthority.stubs(:where).with(snac: /^00C/i).returns(stub_authority)

    get "/local_authorities.json?snac_code=00C"
    parsed_response = JSON.parse(last_response.body)

    assert last_response.ok?
    assert_status_field "ok", last_response
    assert_equal "Solihull Metropolitan Borough Council", parsed_response["results"][0]["name"]
    assert_equal "00CT", parsed_response["results"][0]["snac_code"]
  end

  should "return a JSON formatted array of multiple LocalAuthority objects when searching by name" do
    stub_results = [LocalAuthority.new(name: "Solihull Metropolitan Borough Council", snac: "00CT"),
                    LocalAuthority.new(name: "Solihull Council", snac: "00VT")]
    LocalAuthority.stubs(:where).with(name: /^Solihull/i).returns(stub_results)

    get "/local_authorities.json?name=Solihull"
    parsed_response = JSON.parse(last_response.body)

    expected = [{
                  "name" => "Solihull Metropolitan Borough Council",
                  "snac_code" => "00CT",
                  "id" => "#{base_api_url}/local_authorities/00CT.json"
                },
                {
                  "name" => "Solihull Council",
                  "snac_code" => "00VT",
                  "id" => "#{base_api_url}/local_authorities/00VT.json"
                }]

    assert last_response.ok?
    assert_status_field "ok", last_response
    assert_equal 2, parsed_response["total"]
    assert_equal expected, parsed_response["results"]
  end

  should "return a JSON formatted array of multiple LocalAuthority objects when searching by snac code" do
    stub_result = [LocalAuthority.new(name: "Solihull Metropolitan Borough Council", snac: "00CT"),
                   LocalAuthority.new(name: "Solihull Test Council", snac: "00CF")]
    LocalAuthority.stubs(:where).with(snac: /^00C/i).returns(stub_result)

    get "/local_authorities.json?snac_code=00C"
    parsed_response = JSON.parse(last_response.body)

    assert last_response.ok?
    assert_status_field "ok", last_response
    assert_equal 2, parsed_response["total"]
    assert_equal "Solihull Metropolitan Borough Council", parsed_response["results"][0]["name"]
    assert_equal "00CT", parsed_response["results"][0]["snac_code"]
    assert_equal "Solihull Test Council", parsed_response["results"][1]["name"]
    assert_equal "00CF", parsed_response["results"][1]["snac_code"]
  end

  should "not allow glob searching of snac codes" do
    LocalAuthority.expects(:where).with(snac: /^\*/i).once

    get "/local_authorities.json?snac_code=*"
    parsed_response = JSON.parse(last_response.body)

    assert last_response.ok?
    assert_status_field "ok", last_response
    assert_equal 0, parsed_response["total"]
    assert_equal true, parsed_response["results"].empty?
  end

  should "not allow glob searching of names" do
    LocalAuthority.expects(:where).with(name: /^\*/i).once

    get "/local_authorities.json?name=*"
    parsed_response = JSON.parse(last_response.body)

    assert last_response.ok?
    assert_status_field "ok", last_response
    assert_equal 0, parsed_response["total"]
    assert_equal true, parsed_response["results"].empty?
  end

  should "have a canonical ID for each local authority result when searching" do
    stub_authority = LocalAuthority.new(name: "Solihull Metropolitan Borough Council", snac: "00CT")
    LocalAuthority.stubs(:where).with(snac: /^00C/i).returns(stub_authority)

    get "/local_authorities.json?snac_code=00C"
    parsed_response = JSON.parse(last_response.body)

    assert last_response.ok?
    assert_status_field "ok", last_response
    assert_equal "#{base_api_url}/local_authorities/00CT.json", parsed_response["results"][0]["id"]
  end

  should "have a canonical ID for the provided response when directly accessing with a snac code" do
    stub_authority = LocalAuthority.new(name: "Solihull Metropolitan Borough Council", snac: "00CT")
    LocalAuthority.stubs(:find_by_snac).with("00CT").returns(stub_authority)

    get "/local_authorities/00CT.json"
    parsed_response = JSON.parse(last_response.body)

    assert last_response.ok?
    assert_status_field "ok", last_response
    assert_equal "#{base_api_url}/local_authorities/00CT.json", parsed_response["id"]
  end
end
