require_relative '../test_helper'

class ArtefactWithTagsRequestTest < GovUkContentApiTest

  describe "handling requests with a tag= parameter" do
    it "should return 404 if no tag is provided" do
      Tag.expects(:where).never

      ["/with_tag.json", "/with_tag.json?tag="].each do |url|
        get url
        assert last_response.not_found?
        assert_status_field "not found", last_response
      end
    end

    it "should return 404 if tag not found" do
      Tag.expects(:where).with(tag_id: 'farmers').returns([])

      get "/with_tag.json?tag=farmers"

      assert last_response.not_found?
      assert_status_field "not found", last_response
    end

    it "should return 404 if multiple tags found" do
      tags = %w(section keyword).map { |tag_type|
        Tag.new(tag_id: "ambiguity", title: "Ambiguity", tag_type: tag_type)
      }
      Tag.expects(:where).with(tag_id: "ambiguity").returns(tags)

      get "/with_tag.json?tag=ambiguity"

      assert last_response.not_found?
      assert_status_field "not found", last_response
    end

    it "should redirect to the typed URL with zero results" do
      t = Tag.new(tag_id: 'farmers', title: 'Farmers', tag_type: 'keyword')
      Tag.stubs(:where).with(tag_id: 'farmers').returns([t])

      get "/with_tag.json?tag=farmers"
      assert last_response.redirect?
      assert_equal(
        "http://example.org/with_tag.json?keyword=farmers",
        last_response.location
      )
    end

    it "should redirect to the typed URL with multiple results" do
      farmers = FactoryGirl.create(:tag, tag_id: 'farmers', title: 'Farmers', tag_type: 'keyword')
      FactoryGirl.create(:artefact, owning_app: "smart-answers", keywords: ['farmers'], state: 'live')

      get "/with_tag.json?tag=farmers"
      assert_equal(
        "http://example.org/with_tag.json?keyword=farmers",
        last_response.location
      )
    end

    it "should preserve the specified sort order when redirecting" do
      batman = FactoryGirl.create(:tag, tag_id: 'batman', title: 'Batman', tag_type: 'section')
      get "/with_tag.json?tag=batman&sort=bobbles"
      assert last_response.redirect?
      assert_equal(
        "http://example.org/with_tag.json?section=batman&sort=bobbles",
        last_response.location
      )
    end

    it "should preserve the include_children options when redirecting" do
      batman = FactoryGirl.create(:tag, tag_id: 'batman', title: 'Batman', tag_type: 'section')
      get "/with_tag.json?tag=batman&include_children=1"
      assert last_response.redirect?
      assert_equal(
        "http://example.org/with_tag.json?section=batman&include_children=1",
        last_response.location
      )
    end

    it "should not allow filtering by multiple tags" do
      farmers = FactoryGirl.create(:tag, tag_id: 'crime', title: 'Crime', tag_type: 'section')
      business = FactoryGirl.create(:tag, tag_id: 'business', title: 'Business', tag_type: 'section')

      get "/with_tag.json?tag=crime,business"
      assert last_response.not_found?
      assert_status_field "not found", last_response
    end
  end

  describe "handling requests for typed tags" do
    describe "with a valid request" do
      before :each do
        @farmers = FactoryGirl.create(:tag, tag_id: 'farmers', title: 'Farmers', tag_type: 'keyword')
        @business = FactoryGirl.create(:tag, tag_id: 'business', title: 'Business', tag_type: 'section')
      end

      it "should return an array of results" do
        artefact = FactoryGirl.create(:artefact, owning_app: "smart-answers", keywords: ['farmers'], state: 'live',
                                     description: "Artefact description")

        get "/with_tag.json?keyword=farmers"

        assert last_response.ok?
        assert_status_field "ok", last_response
        parsed_response = JSON.parse(last_response.body)
        assert_equal 1, parsed_response["results"].count

        details = parsed_response["results"].first
        assert_equal artefact.name, details["title"]
        assert_equal artefact.description, details["details"]["description"]
      end

      it "should return the standard response even if zero results" do
        get "/with_tag.json?keyword=farmers"
        parsed_response = JSON.parse(last_response.body)

        assert last_response.ok?
        assert_status_field "ok", last_response
        assert_equal 0, parsed_response["total"]
        assert_equal [], parsed_response["results"]
      end

      it "should not be broken by the foreign-travel-advice special handling" do
        FactoryGirl.create(:artefact, slug: 'foreign-travel-advice', owning_app: "travel-advice-publisher", keywords: ['farmers'], state: 'live')

        get "/with_tag.json?keyword=farmers"

        assert last_response.ok?
        assert_equal 1, JSON.parse(last_response.body)["results"].count
      end

      it "should exclude artefacts which aren't live" do
        draft    = FactoryGirl.create(:non_publisher_artefact, keywords: ['farmers'], state: 'draft')
        live     = FactoryGirl.create(:non_publisher_artefact, keywords: ['farmers'], state: 'live')
        archived = FactoryGirl.create(:non_publisher_artefact, keywords: ['farmers'], state: 'archived')

        get "/with_tag.json?keyword=farmers"

        assert last_response.ok?
        response = JSON.parse(last_response.body)
        assert_equal 1, response["results"].count
        assert_equal "http://example.org/#{live.slug}.json", response["results"][0]["id"]
      end

      it "should exclude unpublished publisher items" do
        artefact = FactoryGirl.create(:artefact, owning_app: "publisher", sections: ['business'])
        FactoryGirl.create(:edition, panopticon_id: artefact.id, state: "ready")

        get "/with_tag.json?section=business"

        assert last_response.ok?, "request failed: #{last_response.status}"
        assert_equal 0, JSON.parse(last_response.body)["results"].count
      end

      describe "including chiuldren in results" do
        before :each do
          @foo = FactoryGirl.create(:tag, tag_id: 'foo', title: 'Business', tag_type: 'section', parent_id: "business")
          @bar = FactoryGirl.create(:tag, tag_id: 'bar', title: 'Bar', tag_type: 'section', parent_id: nil)
          @business_artefact = FactoryGirl.create(:artefact, owning_app: "smart-answers", sections: ['business'], state: 'live')
          @foo_artefact = FactoryGirl.create(:artefact, owning_app: "smart-answers", sections: ['foo'], state: 'live')
          @bar_artefact = FactoryGirl.create(:artefact, owning_app: "smart-answers", sections: ['bar'], state: 'live')
        end

        it "should not include any children by default" do
          get "/with_tag.json?section=business"

          assert last_response.ok?
          parsed_response = JSON.parse(last_response.body)
          assert_equal 1, parsed_response["results"].count
          assert_equal "http://example.org/#{@business_artefact.slug}.json", parsed_response["results"][0]["id"]
        end

        it "should return include children in array of results" do
          get "/with_tag.json?section=business&include_children=1"

          assert last_response.ok?
          assert_equal 2, JSON.parse(last_response.body)["results"].count
        end

        it "should return 501 if more than 1 child requested" do
          get "/with_tag.json?section=business&include_children=2"

          assert_equal 501, last_response.status
          assert_status_field "Include children only supports a depth of 1.", last_response
        end
      end
    end

    describe "error handling" do
      it "should return 404 if typed tag not found" do
        Tag.expects(:by_tag_id).with("farmers", "keyword").returns(nil)

        get "/with_tag.json?keyword=farmers"

        assert last_response.not_found?
        assert_status_field "not found", last_response
      end

      it "should return a 404 if an unsupported sort order is requested" do
        batman = FactoryGirl.create(:tag, tag_id: 'batman', title: 'Batman', tag_type: 'section')
        bat = FactoryGirl.create(:artefact, owning_app: 'publisher', sections: ['batman'], name: 'Bat', slug: 'batman')
        bat_guide = FactoryGirl.create(:guide_edition, panopticon_id: bat.id, state: "published", slug: 'batman')
        get "/with_tag.json?section=batman&sort=bobbles"

        assert last_response.not_found?
        assert_status_field "not found", last_response
      end

      it "should not allow filtering by multiple typed tags" do
        farmers = FactoryGirl.create(:tag, tag_id: 'crime', title: 'Crime', tag_type: 'section')
        business = FactoryGirl.create(:tag, tag_id: 'business', title: 'Business', tag_type: 'section')

        get "/with_tag.json?section=crime,business"
        assert last_response.not_found?
        assert_status_field "not found", last_response
      end
    end
  end
end
