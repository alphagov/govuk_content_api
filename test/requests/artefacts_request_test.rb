require_relative '../test_helper'
require 'gds_api/test_helpers/asset_manager'

class ArtefactsRequestTest < GovUkContentApiTest
  include GdsApi::TestHelpers::AssetManager

  it "should return empty array with no artefacts" do
    get "/artefacts.json"

    assert_equal 200, last_response.status
    assert_status_field "ok", last_response

    parsed_response = JSON.parse(last_response.body)
    assert_equal 0, parsed_response["total"]
    assert_equal [], parsed_response["results"]
  end

  it "should return all artefacts" do
    FactoryGirl.create(:artefact, :name => "Alpha", :state => 'live')
    FactoryGirl.create(:artefact, :name => "Bravo", :state => 'live')
    FactoryGirl.create(:artefact, :name => "Charlie", :state => 'live')

    get "/artefacts.json"

    assert_equal 200, last_response.status
    assert_status_field "ok", last_response

    parsed_response = JSON.parse(last_response.body)

    assert_equal 3, parsed_response["total"]
    assert_equal %w(Alpha Bravo Charlie), parsed_response["results"].map {|a| a["title"]}.sort
  end

  it "should only include live artefacts" do
    FactoryGirl.create(:artefact, :name => "Alpha", :state => 'draft')
    FactoryGirl.create(:artefact, :name => "Bravo", :state => 'live')
    FactoryGirl.create(:artefact, :name => "Charlie", :state => 'archived')

    get "/artefacts.json"

    assert_equal 200, last_response.status
    assert_status_field "ok", last_response

    parsed_response = JSON.parse(last_response.body)

    assert_equal 1, parsed_response["total"]
    assert_equal %w(Bravo), parsed_response["results"].map {|a| a["title"]}.sort
  end

  it "should only include minimal information for each artefact" do
    FactoryGirl.create(:artefact, :slug => "bravo", :name => "Bravo", :state => 'live', :kind => "guide")

    get "/artefacts.json"

    assert_equal 200, last_response.status
    assert_status_field "ok", last_response

    parsed_response = JSON.parse(last_response.body)

    assert_equal 1, parsed_response["total"]

    result = parsed_response["results"].first

    assert_equal %w(id web_url title format).sort, result.keys.sort
    assert_equal "Bravo", result["title"]
    assert_equal "guide", result["format"]
    assert_equal "#{public_web_url}/bravo", result["web_url"]
    assert_equal "http://example.org/bravo.json", result["id"]
  end

  describe "with pagination" do
    def setup
      # Stub this out to avoid configuration changes breaking tests
      app.stubs(:pagination).returns(true)
      Artefact.stubs(:default_per_page).returns(10)
    end

    it "should paginate when there are enough artefacts" do
      FactoryGirl.create_list(:artefact, 25, :state => "live")

      get "/artefacts.json"

      assert last_response.ok?
      parsed_response = JSON.parse(last_response.body)
      assert_equal 10, parsed_response["results"].count
      assert_has_values parsed_response, "total" => 25, "current_page" => 1,
                                         "pages" => 3

      assert_link "next",  "http://example.org/artefacts.json?page=2"
      refute_link "previous"
    end

    it "should display subsequent pages" do
      FactoryGirl.create_list(:artefact, 25, :state => "live")

      get "/artefacts.json?page=3"

      assert last_response.ok?
      parsed_response = JSON.parse(last_response.body)
      assert_equal 5, parsed_response["results"].count
      assert_has_values parsed_response, "total" => 25, "current_page" => 3,
                                         "pages" => 3

      assert_link "previous",  "http://example.org/artefacts.json?page=2"
      refute_link "next"
    end
  end

  describe "without pagination" do
    def setup
      app.stubs(:pagination).returns(false)
    end

    it "should display large numbers of artefacts" do
      FactoryGirl.create_list(:artefact, 25, :state => "live")

      get "/artefacts.json"

      assert last_response.ok?
      parsed_response = JSON.parse(last_response.body)
      assert_equal 25, parsed_response["results"].count
      assert_has_values parsed_response, "total" => 25, "current_page" => 1,
                                         "pages" => 1
      refute_link "next"
      refute_link "previous"
    end
  end

  describe "loading assets from asset-manager" do
    it "should include a caption field" do
      artefact = FactoryGirl.create(:artefact, :slug => "a-video", :state => "live",
                                    :kind => "video", :owning_app => "publisher")
      edition = FactoryGirl.create(:video_edition, :slug => artefact.slug,
                                   :panopticon_id => artefact.id, :state => "published",
                                   :caption_file_id => "512c9019686c82191d000001")

      asset_manager_has_an_asset("512c9019686c82191d000001", {
        "id" => "https://asset-manager.production.alphagov.co.uk/assets/512c9019686c82191d000001",
        "name" => "captions-file.xml",
        "content_type" => "application/xml",
        "file_url" => "https://assets.digital.cabinet-office.gov.uk/media/512c9019686c82191d000001/captions-file.xml",
        "state" => "clean",
      })

      get "/a-video.json"
      assert last_response.ok?
      assert_status_field "ok", last_response

      parsed_response = JSON.parse(last_response.body)
      caption_file_info = {
        "web_url"=>"https://assets.digital.cabinet-office.gov.uk/media/512c9019686c82191d000001/captions-file.xml",
        "content_type"=>"application/xml"
      }
      assert_equal caption_file_info, parsed_response["details"]["caption_file"]
    end
  end
end
