require 'test_helper'

class SearchRequestTest < GovUkContentApiTest
  def test_it_returns_an_array_of_results
    SolrWrapper.any_instance.stubs(:search).returns([
      Document.from_hash(title: 'Result 1', link: 'http://example.com/', description: '1', format: 'answer'),
      Document.from_hash(title: 'Result 2', link: 'http://example2.com/', description: '2', format: 'answer')
    ])

    get "/search.json?q=government+info"
    parsed_response = JSON.parse(last_response.body)

    assert last_response.ok?
    assert_equal 'ok', parsed_response["response"]["status"]
    assert_equal 4, parsed_response["response"]["total"]
    assert_equal 4, parsed_response["response"]["results"].count
    assert_equal 'Result 1', parsed_response["response"]["results"].first['title']
  end

  def test_it_returns_the_standard_response_even_if_zero_results
    SolrWrapper.any_instance.stubs(:search).returns([])

    get "/search.json?q=empty+result+set"
    parsed_response = JSON.parse(last_response.body)

    assert last_response.ok?
    assert_equal 'ok', parsed_response["response"]["status"]
    assert_equal 0, parsed_response["response"]["total"]
  end

  def test_it_returns_503_if_no_solr_connection
    SolrWrapper.any_instance.stubs(:search).raises(Errno::ECONNREFUSED)
    get "/search.json?q=government"

    assert_equal 503, last_response.status
  end

end