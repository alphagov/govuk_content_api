require 'test_helper'
require 'link_header'
require 'uri'

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
      expected_id = "http://example.org/tags/section/crime.json"
      expected_url = "#{public_web_url}/browse/crime"
      assert_equal expected_id, JSON.parse(last_response.body)['results'][0]['id']
      assert_equal nil, JSON.parse(last_response.body)['results'][0]['web_url']
      assert_equal expected_url, JSON.parse(last_response.body)['results'][0]["content_with_tag"]["web_url"]
    end

    it "provides a public API URL when requested through that route" do
      # We identify public API URLs by the presence of an HTTP_API_PREFIX
      # environment variable, set by the internal proxy
      tag = FactoryGirl.create(:tag, tag_id: 'crime')
      get '/tags.json', {}, {'HTTP_API_PREFIX' => 'api'}

      expected_id = "#{public_web_url}/api/tags/section/crime.json"
      assert_equal expected_id, JSON.parse(last_response.body)['results'][0]['id']
    end

    describe "with pagination" do

      def setup
        # Mock out the pagination settings to avoid config changes breaking tests
        app.stubs(:pagination).returns(true)
        Tag.stubs(:default_per_page).returns(10)
      end

      it "paginates large numbers of results" do
        FactoryGirl.create_list(:tag, 25)

        get "/tags.json"

        assert last_response.ok?
        response = JSON.parse(last_response.body)
        assert_equal 10, response['results'].count

        assert_has_values response, "total" => 25, "current_page" => 1,
                                    "start_index" => 1, "pages" => 3

        assert_link "next", "http://example.org/tags.json?page=2"
        refute_link "previous"
      end

      it "displays an intermediate page of results" do
        FactoryGirl.create_list(:tag, 25)

        get "/tags.json?page=2"

        assert last_response.ok?
        response = JSON.parse(last_response.body)
        assert_has_values response, "total" => 25, "current_page" => 2,
                                    "start_index" => 11, "pages" => 3

        assert_link "next", "http://example.org/tags.json?page=3"
        assert_link "previous",  "http://example.org/tags.json?page=1"
      end


      it "displays subsequent pages of results" do
        FactoryGirl.create_list(:tag, 25)

        get "/tags.json?page=3"
        response = JSON.parse(last_response.body)
        assert last_response.ok?
        assert_equal 5, response['results'].count

        assert_has_values response, "total" => 25, "current_page" => 3,
                                    "start_index" => 21, "pages" => 3

        refute_link "next"
        assert_link "previous",  "http://example.org/tags.json?page=2"
      end

      it "404s on too high a page number" do
        FactoryGirl.create_list(:tag, 30)
        get "/tags.json?page=4"
        assert last_response.not_found?
      end

      it "works when displaying the last page with a single item" do
        FactoryGirl.create_list(:tag, 31)
        get "/tags.json?page=4"
        assert last_response.ok?
        assert_equal 1, JSON.parse(last_response.body)['results'].count
      end

      it "404s on a negative page number" do
        FactoryGirl.create_list(:tag, 25)
        get "/tags.json?page=-5"
        assert last_response.not_found?
      end

      it "404s on a non-numeric page number" do
        FactoryGirl.create_list(:tag, 25)
        get "/tags.json?page=chickens"
        assert last_response.not_found?
      end

      it "paginates correctly on filtered tag lists" do
        FactoryGirl.create_list(:tag, 25, tag_type: "section")
        FactoryGirl.create_list(:tag, 20, tag_type: "keyword")

        get "/tags.json?type=section&page=2"
        response = JSON.parse(last_response.body)
        assert last_response.ok?
        assert_equal 10, response['results'].count

        assert_has_values response, "total" => 25, "current_page" => 2,
                                    "start_index" => 11, "pages" => 3

        assert_link "next",  "http://example.org/tags.json?type=section&page=3"
        assert_link "previous",  "http://example.org/tags.json?type=section&page=1"
      end
    end

    describe "without pagination" do
      def setup
        app.stubs(:pagination).returns(false)
      end

      it "displays large numbers of results" do
        FactoryGirl.create_list(:tag, 25)

        get "/tags.json"

        assert last_response.ok?
        response = JSON.parse(last_response.body)
        assert_equal 25, response['results'].count

        assert_has_values response, "total" => 25, "current_page" => 1,
                                    "start_index" => 1, "pages" => 1

        refute_link "next"
        refute_link "previous"
      end

      it "displays a filtered list of results" do
        FactoryGirl.create_list(:tag, 25)
        FactoryGirl.create_list(:tag, 25, tag_type: "keyword")

        get "/tags.json?type=keyword"

        assert last_response.ok?
        response = JSON.parse(last_response.body)
        assert_equal 25, response['results'].count

        assert response["results"].all? { |t| t["details"]["type"] == "keyword" }
      end
    end
  end

  describe "/tags/:tag_id.json" do
    it "should redirect section tags from the old URLs" do
      fake_section = Tag.new(tag_id: "crime", tag_type: "section")
      Tag.expects(:by_tag_id).with("crime", "section").returns(fake_section)
      get "/tags/crime.json"
      assert last_response.redirect?, "Old tag request should redirect"
      assert_equal(
        "http://example.org/tags/section/crime.json",
        last_response.location
      )
    end

    it "should not redirect if it can't find a tag" do
      Tag.expects(:by_tag_id).with("crime", "section").returns(nil)
      get "/tags/crime.json"
      assert last_response.not_found?
    end
  end
end
