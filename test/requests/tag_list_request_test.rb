require 'test_helper'

class TagListRequestTest < GovUkContentApiTest
  describe "/tags.json" do
    it "should load list of tags" do
      FactoryGirl.create_list(:tag, 2)
      get "/tags.json"

      assert last_response.ok?
      assert_status_field "ok", last_response
      response = JSON.parse(last_response.body)
      assert_equal 2, response['results'].count

      # Check pagination info
      assert_has_values response, "total" => 2, "current_page" => 1,
                                  "start_index" => 1, "pages" => 1
    end

    it "should filter all tags by type" do
      FactoryGirl.create(:tag, tag_type: "Section")
      FactoryGirl.create(:tag, tag_type: "Keyword")
      get "/tags.json?type=Section"
      assert last_response.ok?
      assert_status_field "ok", last_response
      assert_equal 1, JSON.parse(last_response.body)['results'].count
    end

    it "should have full uri in id field in index action" do
      tag = FactoryGirl.create(:tag, tag_id: 'crime')
      get "/tags.json"
      expected_id = "http://example.org/tags/crime.json"
      expected_url = "http://www.test.gov.uk/browse/crime"
      assert_equal expected_id, JSON.parse(last_response.body)['results'][0]['id']
      assert_equal nil, JSON.parse(last_response.body)['results'][0]['web_url']
      assert_equal expected_url, JSON.parse(last_response.body)['results'][0]["content_with_tag"]["web_url"]
    end

    it "provides a public API URL when requested through that route" do
      # We identify public API URLs by the presence of an HTTP_API_PREFIX
      # environment variable, set by the internal proxy
      tag = FactoryGirl.create(:tag, tag_id: 'crime')
      get '/tags.json', {}, {'HTTP_API_PREFIX' => 'api'}

      expected_id = "http://www.test.gov.uk/api/tags/crime.json"
      assert_equal expected_id, JSON.parse(last_response.body)['results'][0]['id']
    end

    it "paginates large numbers of results" do
      # Mock out the pagination settings to avoid config changes breaking tests
      Tag.stubs(:default_per_page).returns(10)

      FactoryGirl.create_list(:tag, 25)

      get "/tags.json"

      assert last_response.ok?
      response = JSON.parse(last_response.body)
      assert_equal 10, response['results'].count

      assert_has_values response, "total" => 25, "current_page" => 1,
                                  "start_index" => 1, "pages" => 3

      # Check for a next page link
      # Check for lack of a last page link
    end

    it "displays an intermediate page of results" do
      Tag.stubs(:default_per_page).returns(10)

      FactoryGirl.create_list(:tag, 25)

      get "/tags.json?page=2"

      assert last_response.ok?
      response = JSON.parse(last_response.body)
      assert_has_values response, "total" => 25, "current_page" => 2,
                                  "start_index" => 11, "pages" => 3

      # Check for a next page link
      # Check for a previous page link
    end


    it "displays subsequent pages of results" do
      Tag.stubs(:default_per_page).returns(10)

      FactoryGirl.create_list(:tag, 25)

      get "/tags.json?page=3"
      response = JSON.parse(last_response.body)
      assert last_response.ok?
      assert_equal 5, response['results'].count

      assert_has_values response, "total" => 25, "current_page" => 3,
                                  "start_index" => 21, "pages" => 3

      # Check for lack of a next page link
      # Check for a previous page link
    end

    it "404s on too high a page number" do
      Tag.stubs(:default_per_page).returns(10)

      FactoryGirl.create_list(:tag, 30)
      get "/tags.json?page=4"
      assert last_response.not_found?
    end

    it "works when displaying the last page with a single item" do
      Tag.stubs(:default_per_page).returns(10)

      FactoryGirl.create_list(:tag, 31)
      get "/tags.json?page=4"
      assert last_response.ok?
      assert_equal 1, JSON.parse(last_response.body)['results'].count
    end

    it "404s on a negative page number" do
      Tag.stubs(:default_per_page).returns(10)

      FactoryGirl.create_list(:tag, 25)
      get "/tags.json?page=-5"
      assert last_response.not_found?
    end

    it "404s on a non-numeric page number" do
      Tag.stubs(:default_per_page).returns(10)

      FactoryGirl.create_list(:tag, 25)
      get "/tags.json?page=chickens"
      assert last_response.not_found?
    end
  end
end
