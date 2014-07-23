require "test_helper"
require "presenters/tag_presenter"

describe TagPresenter do

  def mock_tag_without_parent
    mock("tag") do
      expects(:title).returns("Tag")
      expects(:tag_id).returns('tag')
      expects(:tag_type).returns("section")
      expects(:short_description).returns("A tag for stuff")
      expects(:description).returns("A tag for stuff and things")
      expects(:parent).returns(nil)
      expects(:state).returns("live")
    end
  end

  it "should present the tag attributes" do
    mock_url_helper = stub_everything

    presented = TagPresenter.new(mock_tag_without_parent, mock_url_helper).present

    assert_equal "Tag", presented["title"]
    assert_equal "A tag for stuff", presented["details"]["short_description"]
    assert_equal "A tag for stuff and things", presented["details"]["description"]
    assert_equal "section", presented["details"]["type"]
  end

  it "should include API and web URLs" do
    mock_tag = mock_tag_without_parent
    tag_url = stub
    tag_web_url = stub

    mock_url_helper = stub_everything do
      stubs(:tag_url).with(mock_tag).returns(tag_url)
      stubs(:tag_web_url).with(mock_tag).returns(tag_web_url)
    end

    presented = TagPresenter.new(mock_tag, mock_url_helper).present
    assert_equal tag_url, presented["id"]
    assert_equal tag_web_url, presented["web_url"]
  end

  it "should link to the view for content with the tag" do
    mock_tag = mock_tag_without_parent
    tag_url = stub
    tag_web_url = stub

    mock_url_helper = stub_everything do
      stubs(:tagged_content_url).with(mock_tag).returns(tag_url)
      stubs(:tagged_content_web_url).with(mock_tag).returns(tag_web_url)
    end

    presented = TagPresenter.new(mock_tag, mock_url_helper).present
    assert_equal(
      {
        "id" => tag_url,
        "web_url" => tag_web_url
      },
      presented["content_with_tag"]
    )
  end

  it "should include a parent key if there is no parent" do
    presenter = TagPresenter.new(mock_tag_without_parent, stub_everything)
    assert_nil presenter.present.fetch("parent")
  end

  it "should instantiate a presenter for the tag's parent" do
    mock_parent = mock("parent")
    mock_tag = mock("tag") do
      stubs(title: nil, tag_id: nil, tag_type: nil, short_description: nil, description: nil, state: nil)
      expects(:parent).with().times(1..2).returns(mock_parent)
    end

    mock_url_helper = stub_everything

    presenter = TagPresenter.new(mock_tag, mock_url_helper)

    # Add in an expectation that a parent presenter will be constructed
    mock_parent_presenter = mock("parent presenter") do
      expects(:present).with().returns(:parent_hash)
    end
    TagPresenter.expects(:new)
      .with(mock_parent, mock_url_helper)
      .returns(mock_parent_presenter)

    assert_equal :parent_hash, presenter.present["parent"]
  end

  it "should include the tag state" do
    mock_tag = mock_tag_without_parent
    mock_url_helper = stub_everything

    presented = TagPresenter.new(mock_tag, mock_url_helper).present

    assert_equal "live", presented["state"]
  end

end
