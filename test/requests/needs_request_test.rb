require_relative '../test_helper'

class NeedsRequestTest < GovUkContentApiTest

  def make_many_artefacts
    FactoryGirl.create_list(:artefact, 25, :state => "live", :need_ids => ["100001"])
  end

  def bearer_token_for_user_with_permission
    { 'HTTP_AUTHORIZATION' => 'Bearer xyz_has_permission_xyz' }
  end

  def bearer_token_for_user_without_permission
    { 'HTTP_AUTHORIZATION' => 'Bearer xyz_does_not_have_permission_xyz' }
  end


  it "should return empty array if no needs match" do
    get "/for_need/fake.json"

    assert_equal 200, last_response.status
    assert_status_field "ok", last_response

    parsed_response = JSON.parse(last_response.body)
    assert_equal 0, parsed_response["total"]
    assert_equal [], parsed_response["results"]
  end

  it "should return all artefacts that match a need" do
    FactoryGirl.create(:artefact, :name => "Alpha1", :need_ids => ["100001", "100003"], :state => 'live')
    FactoryGirl.create(:artefact, :name => "Alpha2", :need_ids => ["100001"], :state => 'live')
    FactoryGirl.create(:artefact, :name => "Beta 1", :need_ids => ["100002"], :state => 'live')

    get "/for_need/100001.json"

    assert_equal 200, last_response.status
    assert_status_field "ok", last_response

    parsed_response = JSON.parse(last_response.body)

    assert_equal 2, parsed_response["total"]
    assert_equal %w(Alpha1 Alpha2), parsed_response["results"].map {|a| a["title"]}.sort
  end

  it "should only include live artefacts" do
    FactoryGirl.create(:artefact, :need_ids => ["100001", "100003"], :name => "Alpha", :state => 'draft')
    FactoryGirl.create(:artefact, :need_ids => ["100001"], :name => "Bravo", :state => 'live')
    FactoryGirl.create(:artefact, :need_ids => ["100001"], :name => "Charlie", :state => 'archived')

    get "/for_need/100001.json"

    assert_equal 200, last_response.status
    assert_status_field "ok", last_response

    parsed_response = JSON.parse(last_response.body)

    assert_equal 1, parsed_response["total"]
    assert_equal %w(Bravo), parsed_response["results"].map {|a| a["title"]}.sort
  end

  describe "user has permission to view unpublished items" do
    it "should return draft data" do
      FactoryGirl.create(:artefact, :need_ids => ["100001", "100003"], :name => "Alpha", :state => 'draft')
      FactoryGirl.create(:artefact, :need_ids => ["100001"], :name => "Bravo", :state => 'live')
      FactoryGirl.create(:artefact, :need_ids => ["100001"], :name => "Charlie", :state => 'archived')

      Warden::Proxy.any_instance.expects(:authenticate?).returns(true)
      Warden::Proxy.any_instance.expects(:user).returns(ReadOnlyUser.new("permissions" => ["access_unpublished"]))

      get "/for_need/100001.json", {}, bearer_token_for_user_with_permission
      assert_equal 200, last_response.status
      parsed_response = JSON.parse(last_response.body)

      assert_equal 3, parsed_response["total"]
      assert_equal %w(Alpha Bravo Charlie), parsed_response["results"].map {|a| a["title"]}.sort
    end
  end

  describe "with pagination" do
    def setup
      # Stub this out to avoid configuration changes breaking tests
      app.stubs(:pagination).returns(true)
      Artefact.stubs(:default_per_page).returns(10)
    end

    it "should paginate when there are enough matching needs" do
      make_many_artefacts
      base_url = "/for_need/100001.json"
      get base_url

      assert last_response.ok?
      parsed_response = JSON.parse(last_response.body)
      assert_equal 10, parsed_response["results"].count
      assert_has_values parsed_response, "total" => 25, "current_page" => 1,
                                         "pages" => 3

      assert_link "next",  "http://example.org#{base_url}?page=2"
      refute_link "previous"
    end

    it "should display subsequent pages" do
      make_many_artefacts
      base_url = "/for_need/100001.json"

      get "#{base_url}?page=3"

      assert last_response.ok?
      parsed_response = JSON.parse(last_response.body)
      assert_equal 5, parsed_response["results"].count
      assert_has_values parsed_response, "total" => 25, "current_page" => 3,
                                         "pages" => 3

      assert_link "previous",  "http://example.org#{base_url}?page=2"
      refute_link "next"
    end
  end

  describe "without pagination" do
    def setup
      app.stubs(:pagination).returns(false)
    end

    it "should display large numbers of artefacts" do
      make_many_artefacts

      get "/for_need/100001.json"

      assert last_response.ok?
      parsed_response = JSON.parse(last_response.body)
      assert_equal 25, parsed_response["results"].count
      assert_has_values parsed_response, "total" => 25, "current_page" => 1,
                                         "pages" => 1
      refute_link "next"
      refute_link "previous"
    end
  end
end
