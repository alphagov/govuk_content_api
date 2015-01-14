require_relative '../test_helper'

class BusinessSupportSchemesTest < GovUkContentApiTest
  def assert_has_field(parsed_response, field)
    assert parsed_response.has_key?(field), "Field #{field} is MISSING"
  end

  describe "finding business support editions" do
    before do
      @artefact = FactoryGirl.create(:artefact, :live)
      @ed1 = FactoryGirl.create(:business_support_edition,
                                :panopticon_id => @artefact._id,
                                :priority => 1,
                                :short_description => "Alpha desc",
                                :areas => ['1','666','999'],
                                :business_sizes => ['up-to-249'],
                                :locations => ['scotland','england'],
                                :sectors => ['manufacturing','utilities'],
                                :state => 'published')
      @ed2 = FactoryGirl.create(:business_support_edition,
                                :panopticon_id => @artefact._id,
                                :priority => 2,
                                :short_description => "Bravo desc",
                                :areas => ['45','444','666'],
                                :business_sizes => ['up-to-249'],
                                :locations => ['scotland', 'wales'],
                                :state => 'published')
      @ed3 = FactoryGirl.create(:business_support_edition,
                                :panopticon_id => @artefact._id,
                                :priority => 1,
                                :short_description => "Charlie desc",
                                :areas => ['1','2','3'],
                                :business_sizes => ['up-to-1000'],
                                :purposes => ['world-domination'],
                                :state => 'published')
      @ed4 = FactoryGirl.create(:business_support_edition,
                                :panopticon_id => @artefact._id,
                                :priority => 1,
                                :short_description => "Delta desc",
                                :locations => ['wales'],
                                :sectors => ['manufacturing'],
                                :support_types => ['award','loan'],
                                :review_requested_at => Time.zone.now,
                                :state => 'in_review')
      @ed5 = FactoryGirl.create(:business_support_edition,
                                :panopticon_id => @artefact._id,
                                :priority => 1,
                                :short_description => "Echo desc",
                                :areas => ['9','666'],
                                :business_sizes => ['up-to-249'],
                                :locations => ['england'],
                                :support_types => ['grant','loan'],
                                :state => 'published')
      @ed6 = FactoryGirl.create(:business_support_edition,
                                :panopticon_id => @artefact._id,
                                :short_description => "Fox-trot desc",
                                :locations => ['scotland', 'wales'],
                                :state => 'archived')
    end

    it "should return all matching business support editions" do
      get "/business_support_schemes.json?areas=666&business_sizes=up-to-249&locations=england,wales"
      assert_status_field "ok", last_response

      parsed_response = JSON.parse(last_response.body)
      assert_equal 3, parsed_response["total"]
      assert_equal ['Alpha desc', 'Bravo desc', 'Echo desc'], parsed_response["results"].map {|r| r["short_description"] }.sort
    end

    it "should return basic artefact details for each result when queried by facets" do
      get "/business_support_schemes.json?locations=scotland&sectors=utilities"
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

    it "should ignore invalid facet keys" do
      get "/business_support_schemes.json?business_sizes=up-to-249&locations=scotland&wibble=echo"
      assert_status_field "ok", last_response
      parsed_response = JSON.parse(last_response.body)

      assert_equal 2, parsed_response["total"]
      assert_equal ['Alpha desc', 'Bravo desc'], parsed_response["results"].map {|r| r["short_description"].strip }.sort
    end

    it "should only return business support editions with live artefacts" do
      archived_artefact = FactoryGirl.create(:artefact, :archived)
      @ed1.set(:panopticon_id, archived_artefact._id)
      get "/business_support_schemes.json?business_sizes=up-to-249&locations=scotland&wibble=echo"
      assert_status_field "ok", last_response
      parsed_response = JSON.parse(last_response.body)

      assert_equal 1, parsed_response["total"]
      assert_equal ['Bravo desc'], parsed_response["results"].map {|r| r["short_description"].strip }.sort
    end

    it "should only return published business support editions when queried with facets" do
      get "/business_support_schemes.json?locations=scotland"
      assert_status_field "ok", last_response
      parsed_response = JSON.parse(last_response.body)

      assert_equal 2, parsed_response["total"]
      assert_equal ['Alpha desc', 'Bravo desc'], parsed_response["results"].map {|r| r["short_description"] }.sort
    end

    it "should return all results with no query params" do
      get "/business_support_schemes.json"
      assert_status_field "ok", last_response
      parsed_response = JSON.parse(last_response.body)

      assert_equal ["Bravo desc", "Alpha desc", "Charlie desc", "Echo desc"], parsed_response["results"].map { |s| s['short_description'] }
      assert_equal 4, parsed_response["total"]
    end

    it "should order the results by priority and title" do
      get "/business_support_schemes.json?business_sizes=up-to-249&locations=england,wales" do
        assert_status_field "ok", last_response
        parsed_response = JSON.parse(last_response.body)

        assert_equal ['Bravo desc', 'Alpha desc', 'Echo desc'], parsed_response["results"].map{ |r| r['short_description'] }
      end
    end

    it "should set cache-control headers" do
      get "/business_support_schemes.json?locations=scotland,england"
      assert_status_field "ok", last_response

      assert_equal "public, max-age=#{15.minutes.to_i}", last_response.headers["Cache-control"]
    end
  end
end
