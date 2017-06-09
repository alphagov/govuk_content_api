require "test_helper"
require "presenters/result_set_presenter"

describe ResultSetPresenter do

  class DummyResultPresenter
    def initialize(result, url_helper)
      @result = result
    end

    def present
      @result
    end
  end

  def mock_result_set(results)
    mock("result set") do
      expects(:links).returns([])
      expects(:total).returns(results.count)
      expects(:start_index).returns(1)
      expects(:pages).returns(1)
      expects(:page_size).returns(results.count)
      expects(:current_page).returns(1)
      expects(:results).returns(results)
    end
  end

  it "should use a custom presenter class" do
    mock_presenter = mock("result presenter") do
      expects(:present).returns("Hello!")
    end
    stub_url_helper = stub("URL helper")
    mock_presenter_class = mock("result presenter class")
    mock_presenter_class.expects(:new).with(:foo, stub_url_helper).returns(mock_presenter)

    result_set = mock_result_set([:foo])

    presenter = ResultSetPresenter.new(result_set, stub_url_helper, mock_presenter_class)
    presented = presenter.present

    assert_equal ["Hello!"], presented["results"]
  end

  it "should include a description when given" do
    results = (1..5).map do |n| { "n" => n, "title" => "Result #{n}" } end
    result_set = mock_result_set(results)

    presented = ResultSetPresenter.new(
      result_set,
      nil,
      DummyResultPresenter,
      description: "Stuff"
    ).present
    assert_equal "Stuff", presented["description"]
  end
end
