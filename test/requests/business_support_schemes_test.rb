require_relative '../test_helper'

class BusinessSupportSchemesTest < GovUkContentApiTest
  def assert_has_field(parsed_response, field)
    assert parsed_response.has_key?(field), "Field #{field} is MISSING"
  end

  describe "finding business support editions" do
    before do
      @ed1 = FactoryGirl.create(:business_support_edition,
                                :short_description => "Alpha desc", :business_support_identifier => 'alpha', :state => 'published')
      @ed2 = FactoryGirl.create(:business_support_edition,
                                :short_description => "Bravo desc", :business_support_identifier => 'bravo', :state => 'published')
      @ed3 = FactoryGirl.create(:business_support_edition,
                                :short_description => "Charlie desc", :business_support_identifier => 'charlie', :state => 'published')
      @ed4 = FactoryGirl.create(:business_support_edition,
                                :short_description => "Delta desc", :business_support_identifier => 'delta', :state => 'in_review')
      @ed5 = FactoryGirl.create(:business_support_edition,
                                :short_description => "Echo desc", :business_support_identifier => 'echo', :state => 'published')
      @ed6 = FactoryGirl.create(:business_support_edition,
                                :short_description => "Fox-trot desc", :business_support_identifier => 'fox-trot', :state => 'archived')
    end

    it "should return all matching business support editions" do
      get "/business_support_schemes.json?identifiers=alpha,bravo,echo"
      assert_status_field "ok", last_response

      parsed_response = JSON.parse(last_response.body)

      assert_equal 3, parsed_response["total"]
      assert_equal ['Alpha desc', 'Bravo desc', 'Echo desc'], parsed_response["results"].map {|r| r["short_description"] }.sort
    end

    it "should return basic artefact details for each result" do
      get "/business_support_schemes.json?identifiers=alpha"
      assert_status_field "ok", last_response
      parsed_response = JSON.parse(last_response.body)

      assert_equal 1, parsed_response["total"]

      artefact = parsed_response["results"].first

      assert_has_field artefact, 'title'
      assert_has_field artefact, 'id'
      assert_has_field artefact, 'web_url'
      assert_has_field artefact, 'short_description'
      assert_has_field artefact, 'format'

      assert_equal "Alpha desc", artefact["short_description"]
    end

    it "should ignore identifiers with no matching business support edition" do
      get "/business_support_schemes.json?identifiers=alpha,wibble,echo"
      assert_status_field "ok", last_response
      parsed_response = JSON.parse(last_response.body)

      assert_equal 2, parsed_response["total"]
      assert_equal ['Alpha desc', 'Echo desc'], parsed_response["results"].map {|r| r["short_description"].strip }.sort
    end

    it "should only return published business support editions" do
      get "/business_support_schemes.json?identifiers=alpha,delta,echo,fox-trot"
      assert_status_field "ok", last_response
      parsed_response = JSON.parse(last_response.body)

      assert_equal 2, parsed_response["total"]
      assert_equal ['Alpha desc', 'Echo desc'], parsed_response["results"].map {|r| r["short_description"] }
    end

    it "should return an empty result set if nothing matches" do
      get "/business_support_schemes.json?identifiers=delta,wibble,fox-trot"
      assert_status_field "ok", last_response
      parsed_response = JSON.parse(last_response.body)

      assert_equal [], parsed_response["results"]
      assert_equal 0, parsed_response["total"]
    end

    it "should return an empty result set with no query params" do
      get "/business_support_schemes.json"
      assert_status_field "ok", last_response
      parsed_response = JSON.parse(last_response.body)

      assert_equal [], parsed_response["results"]
      assert_equal 0, parsed_response["total"]
    end
  end
end
