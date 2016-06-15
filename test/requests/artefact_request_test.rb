require 'test_helper'
require 'uri'

class ArtefactRequestTest < GovUkContentApiTest

  def bearer_token_for_user_with_permission
    { 'HTTP_AUTHORIZATION' => 'Bearer xyz_has_permission_xyz' }
  end

  def bearer_token_for_user_without_permission
    { 'HTTP_AUTHORIZATION' => 'Bearer xyz_does_not_have_permission_xyz' }
  end

  it "should return 404 if artefact not found" do
    get '/bad-artefact.json'
    assert last_response.not_found?
    assert_status_field "not found", last_response
  end

  it "should return 404 if artefact in draft" do
    artefact = FactoryGirl.create(:non_publisher_artefact, state: 'draft')
    get "/#{artefact.slug}.json"
    assert last_response.not_found?
    assert_status_field "not found", last_response
  end

  it "should return 410 if artefact archived" do
    artefact = FactoryGirl.create(:non_publisher_artefact, state: 'archived')
    get "/#{artefact.slug}.json"
    assert_equal 410, last_response.status
    assert_status_field "gone", last_response
  end

  describe "returning related artefacts" do
    it "should return related artefacts as a combined array" do
      @food_tag = FactoryGirl.create(:live_tag, :tag_id => "food", :tag_type => 'section', :title => "Food")
      FactoryGirl.create(:live_tag, :tag_id => "food/pastries", :tag_type => 'section', :title => "Pastries", :parent_id => @food_tag.tag_id)
      FactoryGirl.create(:live_tag, :tag_id => "food/desserts", :tag_type => 'section', :title => "Desserts", :parent_id => @food_tag.tag_id)

      related_artefacts = [
        FactoryGirl.create(:artefact, slug: "related-artefact-1", name: "Pies", state: 'live', :sections => ["food/pastries"]),
        FactoryGirl.create(:artefact, slug: "related-artefact-2", name: "Cake", state: 'live', :sections => ["food/desserts"])
      ]

      artefact = FactoryGirl.create(:non_publisher_artefact, related_artefacts: related_artefacts, state: 'live', :sections => ["food/pastries"])

      get "/#{artefact.slug}.json"
      parsed_response = JSON.parse(last_response.body)

      assert_equal 200, last_response.status

      assert_status_field "ok", last_response
      assert_equal 2, parsed_response["related"].length
      assert_equal "Pies", parsed_response["related"][0]["title"]
      assert_equal "Cake", parsed_response["related"][1]["title"]
    end

    it "should set the group for a related artefact" do
      FactoryGirl.create(:live_tag, :tag_id => "food/pastries", :tag_type => 'section', :title => "Pastries", :parent_id => "food")
      FactoryGirl.create(:live_tag, :tag_id => "food/desserts", :tag_type => 'section', :title => "Desserts", :parent_id => "food")
      FactoryGirl.create(:live_tag, :tag_id => "drinks/cocktails", :tag_type => 'section', :title => "Cocktails", :parent_id => "drinks")

      related_artefacts = [
        FactoryGirl.create(:artefact, slug: "related-artefact-1", name: "Pies", state: 'live', :sections => ["food/pastries"]),
        FactoryGirl.create(:artefact, slug: "related-artefact-2", name: "Cake", state: 'live', :sections => ["food/desserts"]),
        FactoryGirl.create(:artefact, slug: "related-artefact-3", name: "Mojito", state: 'live', :sections => ["drinks/cocktails"])
      ]

      artefact = FactoryGirl.create(:non_publisher_artefact, related_artefacts: related_artefacts, state: 'live', :sections => ["food/pastries"])

      get "/#{artefact.slug}.json"
      parsed_response = JSON.parse(last_response.body)

      assert_equal 200, last_response.status

      assert_status_field "ok", last_response
      assert_equal 3, parsed_response["related"].length

      assert_equal "subsection", parsed_response["related"][0]["group"]
      assert_equal "section", parsed_response["related"][1]["group"]
      assert_equal "other", parsed_response["related"][2]["group"]
    end

    it "should include related artefacts in their related order, not the natural order" do
      a = FactoryGirl.create(:artefact, name: "A", state: 'live')
      b = FactoryGirl.create(:artefact, name: "B", state: 'live')

      artefact = FactoryGirl.create(:non_publisher_artefact, related_artefacts: [b, a], state: 'live')

      get "/#{artefact.slug}.json"
      parsed_response = JSON.parse(last_response.body)

      assert_equal ["B", "A"], parsed_response["related"].map { |r| r["title"] }
    end

    it "should exclude unpublished related artefacts" do
      related_artefacts = [
        FactoryGirl.create(:artefact, state: 'draft'),
        live = FactoryGirl.create(:artefact, state: 'live'),
        FactoryGirl.create(:artefact, state: 'archived')
      ]

      artefact = FactoryGirl.create(:non_publisher_artefact, related_artefacts: related_artefacts,
          state: 'live', slug: "workaround")

      get "/#{artefact.slug}.json"
      parsed_response = JSON.parse(last_response.body)

      assert_equal 200, last_response.status

      assert_status_field "ok", last_response
      assert_equal 1, parsed_response["related"].length

      assert_equal "http://example.org/#{live.slug}.json", parsed_response['related'][0]["id"]
    end
  end

  describe "returning related external links" do
    before :each do
      @artefact = FactoryGirl.create(:non_publisher_artefact, :state => 'live')
    end

    it "should return an array of external links" do
      @artefact.external_links.build(:title => "Fooey", :url => "http://www.example.com/fooey")
      @artefact.external_links.build(:title => "Gooey", :url => "https://www.example.org/index.html?id=gooey")
      @artefact.external_links.build(:title => "Kablooie", :url => "https://www.example.com/kablooie")
      @artefact.save!

      get "/#{@artefact.slug}.json"
      assert_equal 200, last_response.status
      parsed_response = JSON.parse(last_response.body)

      assert_equal %w(Fooey Gooey Kablooie), parsed_response["related_external_links"].map {|l| l["title"] }
    end

    it "should return empty array is there are no external links" do
      get "/#{@artefact.slug}.json"
      assert_equal 200, last_response.status
      parsed_response = JSON.parse(last_response.body)

      assert_equal [], parsed_response["related_external_links"]
    end
  end

  it 'should return a downtime message if downtime is scheduled' do
    downtime = FactoryGirl.create(:downtime, artefact: FactoryGirl.create(:live_artefact_with_edition))

    get "/#{downtime.artefact.slug}.json"

    assert_equal 200, last_response.status
    assert_equal downtime.message, JSON.parse(last_response.body)['details']['downtime']['message']
  end

  it 'should not return downtime details if downtime is not supposed to be publicised' do
    faraway_downtime = FactoryGirl.create(:downtime, start_time: Date.today + 3, end_time: Date.today + 4, artefact: FactoryGirl.create(:live_artefact_with_edition))

    get "/#{faraway_downtime.artefact.slug}.json"

    assert_equal 200, last_response.status
    assert_nil JSON.parse(last_response.body)['details']['downtime']
  end

  it "should not look for edition if publisher not owner" do
    artefact = FactoryGirl.create(:non_publisher_artefact, state: 'live')

    get "/#{artefact.slug}.json"

    assert_equal 200, last_response.status
    assert_status_field "ok", last_response
    refute JSON.parse(last_response.body)["details"].has_key?('overview')
  end

  it "should give an empty list of tags when there are no tags" do
    artefact = FactoryGirl.create(:non_publisher_artefact, state: 'live')

    get "/#{artefact.slug}.json"

    assert_equal 200, last_response.status
    assert_status_field "ok", last_response
    assert_equal [], JSON.parse(last_response.body)["tags"]
  end

  it "should list section information" do
    crime = FactoryGirl.create(:live_tag, tag_id: "crime", content_id: SecureRandom.uuid, title: "Crime", tag_type: "section")
    batman = FactoryGirl.create(:live_tag, tag_id: "crime/batman", content_id: SecureRandom.uuid, title: "Batman", tag_type: "section", parent_id: crime.tag_id)

    sections = [
      { tag_id: 'crime', parent_id: nil, title: 'Crime', content_id: crime.content_id },
      { tag_id: 'crime/batman', parent_id: 'crime', title: 'Batman', content_id: batman.content_id },
    ]


    artefact = FactoryGirl.create(:non_publisher_artefact,
        sections: sections.map { |section| section[:tag_id] },
        state: 'live')

    get "/#{artefact.slug}.json"

    assert_equal 200, last_response.status
    assert_status_field "ok", last_response
    parsed_artefact = JSON.parse(last_response.body)
    assert_equal 2, parsed_artefact["tags"].length

    # Note that this will check the ordering too
    sections.zip(parsed_artefact["tags"]).each do |section, tag_info|
      assert_equal section[:title], tag_info["title"]
      tag_path = "/tags/section/#{CGI.escape(section[:tag_id])}.json"
      assert_equal tag_path, URI.parse(tag_info["id"]).path
      assert_equal section[:content_id], tag_info["content_id"]
      assert_equal "section", tag_info["details"]["type"]
      # Temporary hack until the browse pages are rebuilt
      expected_section_slug = section[:tag_id]
      assert_equal "#{public_web_url}/browse/#{expected_section_slug}", tag_info["web_url"]
      assert_equal "#{public_web_url}/browse/#{expected_section_slug}", tag_info["content_with_tag"]["web_url"]
    end
  end

  it "excludes draft tags unless requested" do
    sections = [
      { tag_id: 'draft-parent-tag', parent_id: nil, title: 'Draft parent tag' },
      { tag_id: 'crime', parent_id: nil, title: 'Crime' },
      { tag_id: 'crime/batman', parent_id: 'crime', title: 'Batman' },
      { tag_id: 'crime/draft-child-tag', parent_id: 'crime', title: 'Draft child tag' },
    ]

    live_parent = FactoryGirl.create(:live_tag, tag_id: "crime", title: "Crime", tag_type: "section")
    live_child = FactoryGirl.create(:live_tag, tag_id: "crime/batman", title: "Batman", tag_type: "section", parent_id: live_parent.tag_id)
    draft_child = FactoryGirl.create(:draft_tag, tag_id: "crime/draft-child-tag", title: "Draft child tag", tag_type: "section", parent_id: live_parent.tag_id)

    draft_parent = FactoryGirl.create(:draft_tag, tag_id: "draft-parent-tag", title: "Draft parent tag", tag_type: "section")

    artefact = FactoryGirl.create(:non_publisher_artefact,
        sections: sections.map { |section| section[:tag_id] },
        state: 'live')

    get "/#{artefact.slug}.json"
    parsed_artefact = JSON.parse(last_response.body)
    assert_equal [live_parent.title, live_child.title].to_set, parsed_artefact["tags"].map {|tag_info| tag_info["title"] }.to_set

    get "/#{artefact.slug}.json?draft_tags=true"
    parsed_artefact = JSON.parse(last_response.body)
    assert_equal [
      live_parent.title,
      live_child.title,
      draft_child.title,
      draft_parent.title
    ].to_set, parsed_artefact["tags"].map {|tag_info| tag_info["title"] }.to_set
  end

  it "should set the format field at the top-level from the artefact" do
    artefact = FactoryGirl.create(:non_publisher_artefact, state: 'live')
    get "/#{artefact.slug}.json"

    assert_equal 200, last_response.status
    response = JSON.parse(last_response.body)
    assert_equal 'smart-answer', response["format"]
  end

  it "should set the content_id field at the top-level from the artefact" do
    artefact = FactoryGirl.create(:non_publisher_artefact, state: 'live', :content_id => SecureRandom.uuid)
    get "/#{artefact.slug}.json"

    assert_equal 200, last_response.status
    response = JSON.parse(last_response.body)
    assert_equal artefact.content_id, response["content_id"]
  end

  it "should set the language field in the details node of the artefact" do
    artefact = FactoryGirl.create(:non_publisher_artefact, state: 'live')
    get "/#{artefact.slug}.json"

    assert_equal 200, last_response.status
    response = JSON.parse(last_response.body)
    assert_equal 'en', response["details"]["language"]
  end

  describe "in_beta" do
    it "should be true if edition is in beta" do
      artefact = FactoryGirl.create(:artefact, state: 'live')
      edition = FactoryGirl.create(:edition, panopticon_id: artefact.id, state: 'published', in_beta: true)

      get "/#{artefact.slug}.json"

      assert_equal 200, last_response.status
      response = JSON.parse(last_response.body)
      assert response["in_beta"]
    end

    it "should be false if edition is not in beta" do
      artefact = FactoryGirl.create(:artefact, state: 'live')
      edition = FactoryGirl.create(:edition, panopticon_id: artefact.id, state: 'published', in_beta: false)

      get "/#{artefact.slug}.json"

      assert_equal 200, last_response.status
      response = JSON.parse(last_response.body)
      refute response["in_beta"]
    end
  end

  describe "updated timestamp" do

    before do
      @older_timestamp = DateTime.ordinal(2013, 1, 1, 12, 00)
      @newer_timestamp = DateTime.ordinal(2013, 2, 2, 2, 22)
    end

    it "should set the updated_at field at the top-level from the artefact if there's no edition" do
      artefact = FactoryGirl.create(:non_publisher_artefact, state: 'live')
      artefact.update_attribute(:updated_at, @newer_timestamp)
      get "/#{artefact.slug}.json"

      assert_equal 200, last_response.status
      response = JSON.parse(last_response.body)
      assert_equal @newer_timestamp.iso8601, response["updated_at"]
    end

    it "should set the updated_at field from the artefact if it's most recently updated" do
      artefact = FactoryGirl.create(:artefact, state: 'live')
      artefact.update_attribute(:updated_at, @newer_timestamp)
      edition = FactoryGirl.create(:edition, panopticon_id: artefact.id, state: 'published')
      edition.update_attribute(:updated_at, @older_timestamp)
      get "/#{artefact.slug}.json"

      assert_equal 200, last_response.status
      response = JSON.parse(last_response.body)
      assert_equal @newer_timestamp.iso8601, response["updated_at"]
    end

    it "should set the updated_at field from the edition if it's most recently updated" do
      artefact = FactoryGirl.create(:artefact, state: 'live')
      artefact.update_attribute(:updated_at, @older_timestamp)
      edition = FactoryGirl.create(:edition, panopticon_id: artefact.id, state: 'published')
      edition.update_attribute(:updated_at, @newer_timestamp)
      get "/#{artefact.slug}.json"

      assert_equal 200, last_response.status
      response = JSON.parse(last_response.body)
      assert_equal @newer_timestamp.iso8601, response["updated_at"]
    end
  end

  describe "publisher artefacts" do

    describe "with local transactions" do

      describe "with snac code provided" do

        before do
          @service = FactoryGirl.create(:local_service)
          @local_transaction_edition = FactoryGirl.create(:local_transaction_edition,
            lgsl_code: @service.lgsl_code, state: 'published')

          @local_transaction_edition.artefact.update_attribute(:state, 'live')
        end

        it "should return local service, local authority and local interaction details" do
          authority = FactoryGirl.create(
            :local_authority,
            homepage_url: 'http://council.example.gov/',
          )
          interaction = FactoryGirl.create(
            :local_interaction,
            lgsl_code: @service.lgsl_code,
            local_authority: authority
          )

          get "/#{@local_transaction_edition.artefact.slug}.json?snac=#{authority.snac}"
          assert last_response.ok?
          response = JSON.parse(last_response.body)

          assert_equal @service.lgsl_code, response['details']['local_service']['lgsl_code']
          assert_equal @service.providing_tier, response['details']['local_service']['providing_tier']
          assert_equal authority.name, response['details']['local_authority']['name']
          assert_equal 'http://council.example.gov/', response['details']['local_authority']['homepage_url']
          assert_equal interaction.url, response['details']['local_interaction']['url']
        end

        it "should return nil local_interaction when no interaction available" do
          authority = FactoryGirl.create(:local_authority)

          get "/#{@local_transaction_edition.artefact.slug}.json?snac=#{authority.snac}"
          assert last_response.ok?
          response = JSON.parse(last_response.body)

          assert_equal @service.lgsl_code, response['details']['local_service']['lgsl_code']
          assert_equal authority.name, response['details']['local_authority']['name']
          assert_nil response['details']['local_interaction']
        end

        it "should return nil local_interaction and local_authority when no authority available" do

          get "/#{@local_transaction_edition.artefact.slug}.json?snac=00PT"
          assert last_response.ok?
          response = JSON.parse(last_response.body)

          assert_equal @service.lgsl_code, response['details']['local_service']['lgsl_code']
          assert_nil response['details']['local_authority']
          assert_nil response['details']['local_interaction']
        end

      end

      it "should return local_service details for local transactions without snac code" do
        service = FactoryGirl.create(:local_service)
        local_transaction_edition = FactoryGirl.create(:local_transaction_edition,
          lgsl_code: service.lgsl_code, state: 'published')

        local_transaction_edition.artefact.update_attribute(:state, 'live')

        get "/#{local_transaction_edition.artefact.slug}.json"
        assert last_response.ok?
        response = JSON.parse(last_response.body)

        assert_equal service.lgsl_code, response['details']['local_service']['lgsl_code']
        assert_equal service.providing_tier, response['details']['local_service']['providing_tier']
      end

    end

    it "should return 404 if artefact is publication but never published" do
      edition = FactoryGirl.create(:edition)

      get "/#{edition.artefact.slug}.json"

      assert last_response.not_found?
      assert_status_field "not found", last_response
    end

    it "should return 410 if artefact is publication but only archived" do
      artefact = FactoryGirl.create(:artefact, state: 'live')
      edition = FactoryGirl.create(:edition, state: 'archived', panopticon_id: artefact.id)

      get "/#{edition.artefact.slug}.json"

      assert_equal 410, last_response.status
      assert_status_field "gone", last_response
    end

    it "gets the published edition if a previous archived edition exists" do
      artefact = FactoryGirl.create(:artefact, state: 'live')
      edition = FactoryGirl.create(:edition, state: 'archived', panopticon_id: artefact.id)
      FactoryGirl.create(:edition, state: 'published', panopticon_id: artefact.id)

      get "/#{edition.artefact.slug}.json"

      assert last_response.ok?
    end

    it "should set a future Cache-control and Expires header" do
      artefact = FactoryGirl.create(:non_publisher_artefact, state: 'live')

      point_in_time = Time.now
      Timecop.freeze(point_in_time) do
        get "/#{artefact.slug}.json"
      end
      assert_equal "public, max-age=#{15.minutes.to_i}", last_response.headers["Cache-control"]
      fifteen_minutes_from_now = point_in_time + 15.minutes
      assert_equal fifteen_minutes_from_now.httpdate, last_response.headers["Expires"]
    end

    describe "accessing unpublished editions" do
      before do
        @artefact = FactoryGirl.create(:artefact, state: 'live')
        @published = FactoryGirl.create(:edition, panopticon_id: @artefact.id, body: '# Published edition', state: 'published', version_number: 1)
        @draft     = FactoryGirl.create(:edition, panopticon_id: @artefact.id, body: '# Draft edition',     state: 'draft',     version_number: 2)
      end

      it "should return 401 if using edition parameter, not authenticated" do
        get "/#{@artefact.slug}.json?edition=anything"
        assert_equal 401, last_response.status
        assert_status_field "unauthorised", last_response
        assert_status_message "Edition parameter requires authentication", last_response
      end

      it "should return 403 if using edition parameter, authenticated but lacking permission" do
        Warden::Proxy.any_instance.expects(:authenticate?).returns(true)
        Warden::Proxy.any_instance.expects(:user).returns(ReadOnlyUser.new("permissions" => []))
        get "/#{@artefact.slug}.json?edition=2", {}, bearer_token_for_user_without_permission
        assert_equal 403, last_response.status
        assert_status_field "forbidden", last_response
        assert_status_message "You must be authorized to use the edition parameter", last_response
      end

      describe "user has permission" do
        it "should return draft data if using edition parameter, edition is draft" do
          Warden::Proxy.any_instance.expects(:authenticate?).returns(true)
          Warden::Proxy.any_instance.expects(:user).returns(ReadOnlyUser.new("permissions" => ["access_unpublished"]))

          get "/#{@artefact.slug}.json?edition=2", {}, bearer_token_for_user_with_permission
          assert_equal 200, last_response.status
          parsed_response = JSON.parse(last_response.body)
          assert_match(/Draft edition/, parsed_response["details"]["body"])
        end

        it "should return draft data if using edition parameter, edition is draft and artefact is draft" do
          Warden::Proxy.any_instance.expects(:authenticate?).returns(true)
          Warden::Proxy.any_instance.expects(:user).returns(ReadOnlyUser.new("permissions" => ["access_unpublished"]))

          @artefact = FactoryGirl.create(:artefact, state: 'draft')
          @published = FactoryGirl.create(:edition, panopticon_id: @artefact.id, state: 'draft', version_number: 1)

          get "/#{@artefact.slug}.json?edition=1", {}, bearer_token_for_user_with_permission
          assert_equal 200, last_response.status
          JSON.parse(last_response.body)
        end

        it "should 404 if a non-existent edition is requested" do
          Warden::Proxy.any_instance.expects(:authenticate?).returns(true)
          Warden::Proxy.any_instance.expects(:user).returns(ReadOnlyUser.new("permissions" => ["access_unpublished"]))

          get "/#{@artefact.slug}.json?edition=3", {}, bearer_token_for_user_with_permission
          assert_equal 404, last_response.status
        end

        it "should set a private cache-control header with max-age=0" do
          Warden::Proxy.any_instance.expects(:authenticate?).returns(true)
          Warden::Proxy.any_instance.expects(:user).returns(ReadOnlyUser.new("permissions" => ["access_unpublished"]))

          get "/#{@artefact.slug}.json?edition=2", {}, bearer_token_for_user_with_permission

          assert_equal "private, max-age=0", last_response.headers["Cache-control"]
        end

        it "should set an Expires header to the current time to prevent caching" do
          Warden::Proxy.any_instance.expects(:authenticate?).returns(true)
          Warden::Proxy.any_instance.expects(:user).returns(ReadOnlyUser.new("permissions" => ["access_unpublished"]))

          point_in_time = Time.now
          Timecop.freeze(point_in_time) do
            get "/#{@artefact.slug}.json?edition=2", {}, bearer_token_for_user_with_permission
          end
          assert_equal point_in_time.httpdate, last_response.headers["Expires"]
        end
      end
    end

    it "should return publication data if published" do
      artefact = FactoryGirl.create(:artefact, need_ids: ['123412'], state: 'live')
      edition = FactoryGirl.create(:edition, panopticon_id: artefact.id, body: '# Important information', state: 'published')

      get "/#{artefact.slug}.json"
      parsed_response = JSON.parse(last_response.body)

      assert_equal 200, last_response.status

      assert_status_field "ok", last_response
      assert_equal "http://example.org/#{artefact.slug}.json", parsed_response["id"]
      assert_equal "#{public_web_url}/#{artefact.slug}", parsed_response["web_url"]
      assert_equal "<h1>Important information</h1>\n", parsed_response["details"]["body"]
      assert_equal ["123412"], parsed_response["details"]["need_ids"]
      assert_equal edition.updated_at.iso8601, parsed_response["updated_at"]
    end

    it "should set the format from the edition, not the artefact in case the Artefact is out of date" do
      artefact = FactoryGirl.create(:artefact, kind: "answer", state: 'live')
      FactoryGirl.create(:local_transaction_edition, panopticon_id: artefact.id,
            lgsl_code: FactoryGirl.create(:local_service).lgsl_code, state: 'published')

      get "/#{artefact.slug}.json"
      parsed_response = JSON.parse(last_response.body)
      assert_equal "local_transaction", parsed_response["format"]
    end

    it "should set the title from the edition, not the artefact in case the Artefact is out of date" do
      artefact = FactoryGirl.create(:artefact, kind: "answer",
                                    state: 'live', name: "artefact title")
      FactoryGirl.create(:local_transaction_edition, title: "edition title", panopticon_id: artefact.id,
        lgsl_code: FactoryGirl.create(:local_service).lgsl_code,
        state: 'published')
      get "/#{artefact.slug}.json"
      parsed_response = JSON.parse(last_response.body)
      assert_equal "edition title", parsed_response["title"]
    end

    describe "processing content" do
      it "should convert artefact body and part bodies to html" do
        artefact = FactoryGirl.create(:artefact, slug: "annoying", state: 'live')
        FactoryGirl.create(:guide_edition,
            panopticon_id: artefact.id,
            parts: [
              Part.new(title: "Part One", body: "## Header 2", slug: "part-one")
            ],
            state: 'published')

        get "/#{artefact.slug}.json"

        parsed_response = JSON.parse(last_response.body)
        assert_equal 200, last_response.status
        assert_equal "<h2>Header 2</h2>\n", parsed_response["details"]["parts"][0]["body"]
      end

      it "should return govspeak in artefact body and part bodies if requested" do
        artefact = FactoryGirl.create(:artefact, slug: "annoying", state: 'live')
        FactoryGirl.create(:guide_edition,
            panopticon_id: artefact.id,
            parts: [
              Part.new(title: "Part One", body: "## Header 2", slug: "part-one")
            ],
            state: 'published')

        get "/#{artefact.slug}.json?content_format=govspeak"

        parsed_response = JSON.parse(last_response.body)
        assert_equal 200, last_response.status
        assert_equal "## Header 2", parsed_response["details"]["parts"][0]["body"]
      end
    end

    it "should return parts in the correct order" do
      artefact = FactoryGirl.create(:artefact, state: 'live')
      FactoryGirl.create(:guide_edition,
        panopticon_id: artefact.id,
        parts: [
          Part.new(title: "Part Two", order: 2, body: "## Header 3", slug: "part-two"),
          Part.new(title: "Part One", order: 1, body: "## Header 2", slug: "part-one")
        ],
        state: 'published')

      get "/#{artefact.slug}.json"

      parsed_response = JSON.parse(last_response.body)
      assert_equal 200, last_response.status
      expected_first_part = {
        "web_url" => "#{public_web_url}/#{artefact.slug}/part-one",
        "slug" => "part-one",
        "order" => 1,
        "title" => "Part One",
        "body" => "<h2>Header 2</h2>\n"
      }
      assert_equal expected_first_part, parsed_response["details"]["parts"][0]
    end
  end
end
