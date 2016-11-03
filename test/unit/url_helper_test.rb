require "test_helper"
require "url_helper"

describe URLHelper do
  class MockApp
    def self.url(u)
      u
    end
  end

  it "should use the app's `url` method when there is no prefix" do
    mock_app = mock("app") do
      expects(:url).with("/foobang").returns("http://example.com/foobang")
    end
    helper = URLHelper.new(mock_app, nil, nil)
    assert_equal "http://example.com/foobang", helper.api_url("/foobang")
  end

  it "should use the app's `url` method when the prefix is empty" do
    mock_app = mock("app") do
      expects(:url).with("/foobang").returns("http://example.com/foobang")
    end
    helper = URLHelper.new(mock_app, nil, "")
    assert_equal "http://example.com/foobang", helper.api_url("/foobang")
  end

  it "should use the website root when there is an API prefix" do
    mock_app = mock("app") do
      expects(:uri).never
    end
    helper = URLHelper.new(mock_app, "http://example.com", "api")
    assert_equal "http://example.com/api/foobang", helper.api_url("/foobang")
  end

  it "should produce public web URLs" do
    mock_app = mock("app") do
      expects(:uri).never
    end
    helper = URLHelper.new(mock_app, "http://example.com", nil)
    assert_equal "http://example.com/foobang", helper.public_web_url("/foobang")
  end
end
