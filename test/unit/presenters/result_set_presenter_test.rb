require "test_helper"
require "presenters/result_set_presenter"
require "pagination"

describe ResultSetPresenter do
  def mock_result_set(results)
    mock("result set") do
      expects(:total).returns(results.count)
      expects(:start_index).returns(1)
      expects(:pages).returns(1)
      expects(:page_size).returns(results.count)
      expects(:current_page).returns(1)
      expects(:results).returns(results)
    end
  end

  it "should provide pagination data" do
    results = (1..5)
    result_set = mock_result_set(results)

    presented = ResultSetPresenter.new(result_set).present

    assert_equal({ "status" => "ok" }, presented["_response_info"])
    assert_equal 5, presented["total"]
    assert_equal 1, presented["start_index"]
    assert_equal 1, presented["pages"]
    assert_equal 5, presented["page_size"]
    assert_equal 1, presented["current_page"]
  end

  it "should list results as given" do
    results = (1..5).map do |n| { "n" => n, "title" => "Result #{n}" } end
    result_set = mock_result_set(results)

    presented = ResultSetPresenter.new(result_set).present

    assert_equal 5, presented["results"].count

    presented["results"].each_with_index do |result, index|
      assert_equal(["n", "title"], result.keys.sort)
      assert_equal(index + 1, result["n"])
      assert_equal("Result #{index + 1}", result["title"])
    end
  end

  it "should use a custom presenter class" do
    mock_presenter = mock("result presenter") do
      expects(:present).returns("Hello!")
    end
    mock_presenter_class = mock("result presenter class")
    mock_presenter_class.expects(:is_a?).with(Class).returns(true)
    mock_presenter_class.expects(:new).with(:foo).returns(mock_presenter)
    result_set = mock_result_set([:foo])

    presenter = ResultSetPresenter.new(result_set, mock_presenter_class)
    presented = presenter.present

    assert_equal ["Hello!"], presented["results"]
  end

  it "should use a custom presenter callable" do
    mock_presenter = mock("result presenter") do
      expects(:present).returns("Hello!")
    end
    mock_presenter_class = mock("result presenter class")
    mock_presenter_class.expects(:is_a?).with(Class).returns(true)
    mock_presenter_class.expects(:new).with(:foo).returns(mock_presenter)
    result_set = mock_result_set([:foo])

    presenter = ResultSetPresenter.new(result_set, mock_presenter_class)
    presented = presenter.present

    assert_equal ["Hello!"], presented["results"]
  end

  it "should include a description when given" do
    results = (1..5).map do |n| { "n" => n, "title" => "Result #{n}" } end
    result_set = mock_result_set(results)

    presented = ResultSetPresenter.new(
      result_set,
      nil,
      description: "Stuff"
    ).present
    assert_equal "Stuff", presented["description"]
  end
end
