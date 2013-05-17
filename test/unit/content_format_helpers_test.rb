require "test_helper"
require "content_format_helpers"

describe "ContentFormatHelpers" do
  include ContentFormatHelpers

  it "should return govspeak if asking for govspeak format" do
    assert_equal "This is a **test**", format_content("This is a **test**", "govspeak")
  end
end
