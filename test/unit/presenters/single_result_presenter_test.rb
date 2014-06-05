require "test_helper"
require "presenters/single_result_presenter"

describe SingleResultPresenter do
  it "should wrap the presenter with response info" do
    result_presenter = mock("result presenter") do
      expects(:present).returns({"foo" => "bang"})
    end

    expected_hash = {
      "_response_info" => { "status" => "ok" },
      "foo" => "bang"
    }

    presenter = SingleResultPresenter.new(result_presenter)
    assert_equal expected_hash, presenter.present
  end

  it "should delegate the #edition method" do
    edition = Object.new

    mock_presenter = mock("presenter") do
      expects(:edition).returns(edition)
    end

    assert_equal edition, SingleResultPresenter.new(mock_presenter).edition
  end
end
