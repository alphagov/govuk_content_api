require "test_helper"
require "content_format_helpers"

describe "ContentFormatHelpers" do
  include ContentFormatHelpers

  it "should return govspeak if asking for govspeak format" do
    assert_equal "This is a **test**", format_content("This is a **test**", "govspeak")
  end

  describe "DataApi insertion" do
    it "should silently convert [DataApi:<id>] into nothing if there is no Data with id = <id>" do
      DataApi.stubs(:find_by_id).with("4f8583b5e5a4e46a64000002").returns(nil)
      assert_equal "\n", format_content("[DataApi:4f8583b5e5a4e46a64000002]")
    end
  end
end
