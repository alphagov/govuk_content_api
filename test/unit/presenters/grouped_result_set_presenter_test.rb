require "test_helper"
require "presenters/result_set_presenter"
require "presenters/grouped_result_set_presenter"
require "pagination"

describe GroupedResultSetPresenter do

  class DummyResultPresenter
    def initialize(result, url_helper)
      @result = result
    end

    def present
      @result
    end
  end

  DummyArtefact = Struct.new(:kind)

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

  it "groups service formats" do
    results = [
      DummyArtefact.new("answer"),
      DummyArtefact.new("guide"),
      DummyArtefact.new("transaction"),
      DummyArtefact.new("licence"),
    ]
    result_set = mock_result_set(results)
    presented = GroupedResultSetPresenter.new(result_set, nil, DummyResultPresenter).present

    assert_equal 1, presented["grouped_results"].size
    assert_equal "Services", presented["grouped_results"][0]["name"]
    assert_equal ["answer", "guide", "licence", "transaction"], presented["grouped_results"][0]["formats"].sort

    items = presented["grouped_results"][0]["items"]
    assert_equal 4, items.size
    assert_equal ["answer", "guide", "licence", "transaction"], items.map(&:kind).sort
  end

  it "groups guidance formats" do
    results = [
      DummyArtefact.new("guidance"),
      DummyArtefact.new("detailed_guide")
    ]
    result_set = mock_result_set(results)
    presented = GroupedResultSetPresenter.new(result_set, nil, DummyResultPresenter).present

    assert_equal 1, presented["grouped_results"].size
    assert_equal "Guidance", presented["grouped_results"][0]["name"]
    assert_equal ["detailed_guide", "guidance"], presented["grouped_results"][0]["formats"].sort

    items = presented["grouped_results"][0]["items"]
    assert_equal 2, items.size
    assert_equal ["detailed_guide", "guidance"], items.map(&:kind).sort
  end

  it "groups statistics formats" do
    results = [
      DummyArtefact.new("statistics"),
      DummyArtefact.new("statistical_data_set")
    ]
    result_set = mock_result_set(results)
    presented = GroupedResultSetPresenter.new(result_set, nil, DummyResultPresenter).present

    assert_equal 1, presented["grouped_results"].size
    assert_equal "Statistics", presented["grouped_results"][0]["name"]
    assert_equal ["statistical_data_set", "statistics"], presented["grouped_results"][0]["formats"].sort

    items = presented["grouped_results"][0]["items"]
    assert_equal 2, items.size
    assert_equal ["statistical_data_set", "statistics"], items.map(&:kind).sort
  end

  it "groups announcement formats" do
    formats = [
      "authored_article",
      "draft_text",
      "government_response",
      "news_story",
      "oral_statement",
      "press_release",
      "speaking_notes",
      "transcript",
      "world_location_news_article",
      "written_statement"
    ]

    results = formats.map {|format|
      DummyArtefact.new(format)
    }
    result_set = mock_result_set(results)
    presented = GroupedResultSetPresenter.new(result_set, nil, DummyResultPresenter).present

    assert_equal 1, presented["grouped_results"].size
    assert_equal "Announcements", presented["grouped_results"][0]["name"]
    assert_equal formats, presented["grouped_results"][0]["formats"].sort

    items = presented["grouped_results"][0]["items"]
    assert_equal formats.size, items.size
    assert_equal formats, items.map(&:kind).sort
  end

  it "sorts each group by the order in which they are defined" do
    formats = ["news_story", "answer", "guidance", "map", "detailed_guide", "guide", "independent_report"]

    results = formats.map {|format|
      DummyArtefact.new(format)
    }
    result_set = mock_result_set(results)
    presented = GroupedResultSetPresenter.new(result_set, nil, DummyResultPresenter).present

    expected_group_order = [
      "Services",
      "Guidance",
      "Maps",
      "Independent reports",
      "Announcements"
    ]
    assert_equal expected_group_order, presented["grouped_results"].map {|group| group["name"] }
  end

  it "excludes content that's not in a format group" do
    formats = [
      "answer",
      "guide",
      "guidance",
      "something-else"
    ]
    results = formats.map {|format|
      DummyArtefact.new(format)
    }
    result_set = mock_result_set(results)
    presented = GroupedResultSetPresenter.new(result_set, nil, DummyResultPresenter).present

    combined_items = presented["grouped_results"].map {|group| group["items"] }.flatten
    refute combined_items.map(&:kind).include?("something-else")
  end
end
