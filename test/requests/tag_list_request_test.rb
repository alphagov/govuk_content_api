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
      FactoryGirl.create(:tag, tag_type: "section")
      FactoryGirl.create(:tag, tag_type: "keyword")
      get "/tags.json?type=section"
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

    it "returns children of a provided parent tag" do
      FactoryGirl.create(:tag, tag_type: "drink", tag_id: "tea")
      FactoryGirl.create(:tag, tag_type: "drink", tag_id: "tea/lancashire-tea", parent_id: "tea")

      get "/tags.json?type=drink&parent_id=tea"

      assert last_response.ok?
      response = JSON.parse(last_response.body)

      assert_equal 1, response["results"].count
      assert_equal "http://example.org/tags/drink/tea%2Flancashire-tea.json", response["results"][0]["id"]
    end

    it "returns tags in alphabetical order" do
      FactoryGirl.create(:tag, tag_type: "drink", tag_id: "item-1", title: "Tea")
      FactoryGirl.create(:tag, tag_type: "drink", tag_id: "item-2", title: "Coffee")
      FactoryGirl.create(:tag, tag_type: "drink", tag_id: "item-3", title: "Orange Juice")

      get "/tags.json?type=drink&sort=alphabetical"

      assert last_response.ok?
      response = JSON.parse(last_response.body)

      assert_equal 3, response["results"].count
      assert_equal "Coffee", response["results"][0]["title"]
      assert_equal "Orange Juice", response["results"][1]["title"]
      assert_equal "Tea", response["results"][2]["title"]
    end

    it "returns children of a provided parent tag in alphabetical order" do
      FactoryGirl.create(:tag, tag_type: "drink", tag_id: "tea")
      FactoryGirl.create(:tag, tag_type: "drink", tag_id: "tea/blend-1", parent_id: "tea", title: "Yorkshire Tea")
      FactoryGirl.create(:tag, tag_type: "drink", tag_id: "tea/blend-2", parent_id: "tea", title: "Lancashire Tea")
      FactoryGirl.create(:tag, tag_type: "drink", tag_id: "tea/blend-3", parent_id: "tea", title: "PG Tips")

      get "/tags.json?type=drink&parent_id=tea&sort=alphabetical"

      assert last_response.ok?
      response = JSON.parse(last_response.body)

      assert_equal 3, response["results"].count
      assert_equal "Lancashire Tea", response["results"][0]["title"]
      assert_equal "PG Tips", response["results"][1]["title"]
      assert_equal "Yorkshire Tea", response["results"][2]["title"]
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

  describe "/tags/:tag_type.json" do
    it "should redirect to a plural tag type" do
      get "/tags/section.json"
      assert last_response.redirect?
      assert_equal(
        "http://example.org/tags/sections.json",
        last_response.location
      )
    end

    it "should list all tags with a given type" do
      fake_tags = %w(crime housing batman).map { |tag_id|
        Tag.new(tag_id: tag_id, tag_type: "section", name: tag_id.capitalize)
      }
      Tag.expects(:where).with(tag_type: "section").returns(fake_tags)

      get "/tags/sections.json"
      assert last_response.ok?
      assert_status_field "ok", last_response
      response = JSON.parse(last_response.body)
      assert_equal 3, response["results"].length
    end

    it "should 404 on an unknown plural tag type" do
      Tag.expects(:by_tag_id).with("pies", "section").returns(nil)

      get "/tags/pies.json"
      assert last_response.not_found?
    end

    it "should 404 on an unknown singular tag type" do
      Tag.expects(:by_tag_id).with("badger", "section").returns(nil)

      get "/tags/badger.json"
      assert last_response.not_found?
    end
  end

  describe "/tags/sections.json" do
    def setup
      %w(crime housing batman).each do |tag_id|
        FactoryGirl.create :tag, tag_id: tag_id, title: tag_id.capitalize
      end

      %w(joker scarecrow bane).each do |tag_id|
        FactoryGirl.create(
          :tag,
          tag_id: tag_id,
          title: tag_id.capitalize,
          parent_id: "crime"
        )
      end
    end

    def assert_tag_titles(tag_titles)
      response = JSON.parse(last_response.body)
      # NOTE: doesn't check that the tags are in the order given
      assert_equal(
        tag_titles.sort,
        response["results"].map { |tag| tag["title"] }.sort
      )
    end

    it "should list all root-level sections" do
      get "/tags/sections.json?root_sections=true"
      assert_tag_titles %w(Crime Housing Batman)
    end

    it "should list all sections with a given parent" do
      get "/tags/sections.json?parent_id=crime"
      assert_tag_titles %w(Joker Scarecrow Bane)
    end

    it "should reject requests for root sections with a given parent" do
      get "/tags/sections.json?root_sections=true&parent_id=crime"
      assert last_response.not_found?
    end

    it "should 404 on an unknown parent section" do
      get "/tags/sections.json?parent_id=horses"
      assert last_response.not_found?
    end

    it "should display an empty list if there are no sub-sections" do
      get "/tags/sections.json?parent_id=housing"
      assert_tag_titles []
    end
  end
end
