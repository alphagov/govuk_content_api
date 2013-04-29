require 'test_helper'

class SearchRequestTest < GovUkContentApiTest
  it "should 404 when asked for a bad index" do
    get "/search.json?q=government&index=fake"
    assert last_response.not_found?
  end

  def sample_results
    [
      {
        'title' => "Nick Harvey MP (Minister of State (Minister for the Armed Forces), Ministry of Defence)",
        'link' => "/government/ministers/minister-of-state-minister-for-the-armed-forces",
        'format' => "minister",
        'description' => "Nick Harvey was appointed Minister for the Armed Forces in May 2010. He is the MP for North Devon.",
        'indexable_content' => "Nick Harvey was appointed Minister for the Armed Forces in May 2010. He is the MP for North Devon.",
        'highlight' => nil,
        'presentation_format' => "minister",
        'humanized_format' => "Ministers"
      },
      {
        'title' => "Armed Forces Compensation Scheme",
        'link' => "/armed-forces-compensation-scheme",
        'format' => "programme",
        'section' => "work",
        'subsection' => "work-related-benefits-and-schemes",
        'description' => "Overview The Armed Forces Compensation Scheme helps to support",
        'indexable_content' => "Overview The Armed Forces Compensation Scheme helps to support",
        'highlight' => nil,
        'presentation_format' => "programme",
        'humanized_format' => "Benefits & credits"
      }
    ]
  end

  it "should return an array of results" do
    GdsApi::Rummager.any_instance.stubs(:search).returns(sample_results)
    get "/search.json?q=government+info"
    parsed_response = JSON.parse(last_response.body)

    assert last_response.ok?
    assert_status_field "ok", last_response
    assert_equal 2, parsed_response["total"]
    assert_equal 2, parsed_response["results"].count
    assert_equal 'Nick Harvey MP (Minister of State (Minister for the Armed Forces), Ministry of Defence)',
      parsed_response["results"].first['title']
  end

  it "should return the standard response even if zero results" do
    GdsApi::Rummager.any_instance.stubs(:search).returns([])

    get "/search.json?q=empty+result+set"
    parsed_response = JSON.parse(last_response.body)

    assert last_response.ok?
    assert_status_field "ok", last_response
    assert_equal 0, parsed_response["total"]
  end

  it "should default to the mainstream index" do
    search_stub = stub(search: sample_results)
    GdsApi::Rummager.expects(:new).with { |u| u.match /mainstream/ }.returns(search_stub)
    get "/search.json?q=something"
    assert last_response.ok?
  end

  it "should include proper URLs for each response" do
    GdsApi::Rummager.any_instance.stubs(:search).returns(sample_results)
    get "/search.json?q=government+info"

    assert last_response.ok?
    assert_status_field "ok", last_response

    parsed_response = JSON.parse(last_response.body)
    first_response = parsed_response['results'][0]

    assert ! URI.parse(first_response['id']).host.nil?,
      "ID doesn't have a hostname"
    assert ! URI.parse(first_response['web_url']).host.nil?,
      "web_url doesn't have a hostname"
  end

  it "should return 503 if connection times out" do
    GdsApi::Rummager.any_instance.stubs(:search).raises(GdsApi::Rummager::SearchTimeout)
    get "/search.json?q=government"

    assert_equal 503, last_response.status
  end

  it "should return a valid web_url for recommended-links (off-site links)" do
    rummager_response = [
      {
        "title" => "EHIC - NHS Choices",
        "description" => "Apply for a free European Health Insurance Card (EHIC) or renew your card for emergency healthcare in Europe",
        "format" => "recommended-link",
        "link" => "http://www.nhs.uk/ehic",
        "indexable_content" => "ehic, e111, european health insurance card, european health card, travel abroad, travel insurance",
        "es_score" => 3.3209536,
        "highlight" => nil,
        "presentation_format" => "recommended_link",
        "humanized_format" => "Recommended links"}
    ]
    GdsApi::Rummager.any_instance.stubs(:search).returns(rummager_response)
    get "/search.json?q=ehic"

    parsed_response = JSON.parse(last_response.body)
    assert_equal 'http://www.nhs.uk/ehic', parsed_response["results"].first['web_url']
  end
end
