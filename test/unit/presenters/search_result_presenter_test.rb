require "test_helper"
require "presenters/search_result_presenter"

describe SearchResultPresenter do

  it "should present the search result" do
    result = {
      "link" => "/a-thing",
      "title" => "A Thing",
      "description" => "Stuff"
    }

    mock_url_helper = mock("URL helper") do
      expects(:api_url).with("/a-thing").returns("http://example.com/api/a-thing")
      expects(:public_web_url).with("/a-thing").returns("http://example.com/a-thing")
    end

    expected_hash = {
      "id" => "http://example.com/api/a-thing.json",
      "web_url" => "http://example.com/a-thing",
      "title" => "A Thing",
      "details" => { "description" => "Stuff" }
    }
    presenter = SearchResultPresenter.new(result, mock_url_helper)
    assert_equal expected_hash, presenter.present
  end

  it "should present external links" do
    result = {
      "link" => "http://example.com/a-thing",
      "title" => "A Thing",
      "description" => "Stuff"
    }

    mock_url_helper = mock("URL helper") do
      expects(:api_url).never
      expects(:public_web_url).never
    end

    expected_hash = {
      "id" => nil,
      "web_url" => "http://example.com/a-thing",
      "title" => "A Thing",
      "details" => { "description" => "Stuff" }
    }
    presenter = SearchResultPresenter.new(result, mock_url_helper)
    assert_equal expected_hash, presenter.present
  end
end
