require_relative '../test_helper'

class ArtefactsRequestTest < GovUkContentApiTest

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

  describe "pagination" do
    it "should paginate 500 per page when there are enough artefacts" do
      FactoryGirl.create_list(:artefact, 505, :state => "live")

      get "/artefacts.json"

      assert last_response.ok?
      parsed_response = JSON.parse(last_response.body)
      assert_equal 500, parsed_response["results"].count
      assert_has_values parsed_response, "total" => 505, "current_page" => 1,
                                         "pages" => 2

      assert_link "next",  "http://example.org/artefacts.json?page=2"
      refute_link "previous"

      get "/artefacts.json?page=2"

      assert last_response.ok?
      parsed_response = JSON.parse(last_response.body)
      assert_equal 5, parsed_response["results"].count
      assert_has_values parsed_response, "total" => 505, "current_page" => 2,
                                         "pages" => 2

      assert_link "previous",  "http://example.org/artefacts.json?page=1"
      refute_link "next"
    end
  end
end
