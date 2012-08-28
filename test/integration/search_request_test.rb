require 'test_helper'

class SearchRequestTest < GovUkContentApiTest
  should "return an array of results" do
    SolrWrapper.any_instance.stubs(:search).returns([
      Document.from_hash(title: 'Result 1', link: 'http://example.com/', description: '1', format: 'answer'),
      Document.from_hash(title: 'Result 2', link: 'http://example2.com/', description: '2', format: 'answer')
    ])

    get "/search.json?q=government+info"
    parsed_response = JSON.parse(last_response.body)

    assert last_response.ok?
    assert_equal 'ok', parsed_response["response"]["status"]
    assert_equal 2, parsed_response["response"]["total"]
    assert_equal 2, parsed_response["response"]["results"].count
    assert_equal 'Result 1', parsed_response["response"]["results"].first['title']
  end

  should "return the standard response even if zero results" do
    SolrWrapper.any_instance.stubs(:search).returns([])

    get "/search.json?q=empty+result+set"
    parsed_response = JSON.parse(last_response.body)

    assert last_response.ok?
    assert_equal 'ok', parsed_response["response"]["status"]
    assert_equal 0, parsed_response["response"]["total"]
  end

  should "return 503 if no solr connection" do
    SolrWrapper.any_instance.stubs(:search).raises(Errno::ECONNREFUSED)
    get "/search.json?q=government"

    assert_equal 503, last_response.status
  end

end