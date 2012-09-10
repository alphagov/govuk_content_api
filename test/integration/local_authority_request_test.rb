require "test_helper"

class LocalAuthorityRequestTest < GovUkContentApiTest
  def assert_status_field(expected, response)
    assert_equal expected, JSON.parse(response.body)["_response_info"]["status"]
  end

  should "return 404 if no snac code is provided" do
    get "/local_authority.json"
    assert last_response.not_found?
    assert_status_field "not found", last_response
  end

  should "return 404 if no council name is provided" do
    get "/local_authorities.json"
    assert last_response.not_found?
    assert_status_field "not found", last_response
  end

  should "return 404 if LocalAuthority with the provided snac code not found" do
    get "/local_authority/gobble_de_gook.json"
    assert last_response.not_found?
    assert_status_field "not found", last_response
  end

  should "return 404 if LocalAuthority with the provided council name not found" do
    get "/local_authorities.json?council=Somewhere%20over%20the%20rainbow"
    assert last_response.not_found?
    assert_status_field "not found", last_response
  end

  should "return a JSON formatted LocalAuthority when querying with a known snac code" do
    stub_authority = LocalAuthority.new(name: "Super Nova", snac: "supernova")
    LocalAuthority.stubs(:find_by_snac).with("supernova").returns(stub_authority)

    get "/local_authority/supernova.json"
    parsed_response = JSON.parse(last_response.body)

    assert last_response.ok?
    assert_status_field "ok", last_response
    assert_equal "Super Nova", parsed_response["name"]
    assert_equal "supernova", parsed_response["snac_code"]
  end

  should "return a JSON formatted array of LocalAuthority objects when searching by council" do
    stub_authority = LocalAuthority.new(name: "Solihull Metropolitan Borough Council", snac: "00CT")
    LocalAuthority.stubs(:where).with(name: /^Solihull Metro/i).returns(stub_authority)

    get "/local_authorities.json?council=Solihull%20Metro"
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

  should "return a JSON formatted array of multiple LocalAuthority objects when searching by council" do
    stub_results = [LocalAuthority.new(name: "Solihull Metropolitan Borough Council", snac: "00CT"),
                    LocalAuthority.new(name: "Solihull Council", snac: "00VT")]
    LocalAuthority.stubs(:where).with(name: /^Solihull/i).returns(stub_results)

    get "/local_authorities.json?council=Solihull"
    parsed_response = JSON.parse(last_response.body)

    expected = [{"name"=>"Solihull Metropolitan Borough Council", "snac_code"=>"00CT"},
                {"name"=>"Solihull Council", "snac_code"=>"00VT"}]

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

  should "not allow regex searching of snac codes" do
    get "/local_authorities.json?snac_code=*"
    assert last_response.not_found?
  end

  should "not allow regex searching of council" do
    get "/local_authorities.json?council=*"
    assert last_response.not_found?
  end
end
