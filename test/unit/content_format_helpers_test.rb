require "test_helper"
require "content_format_helpers"

describe "ContentFormatHelpers" do
  include ContentFormatHelpers

  it "should return govspeak if asking for govspeak format" do
    assert_equal "This is a **test**", format_content("This is a **test**", "govspeak")
  end

  describe "DataApi insertion" do
    it "should silently convert [DataApi:<id>] into nothing if there is no data" do
      DataApi.stubs(:find_by_id).with("4f8583b5e5a4e46a64000002").returns(nil)
      assert_equal "\n", format_content("[DataApi:4f8583b5e5a4e46a64000002]")
    end

    it "should replace [DataApi:<id>] with the relevant value if there is data" do
      DataApi.stubs(:find_by_id).with("4f8583b5e5a4e46a64000002").returns("20%")
      assert_equal "<p>The vat rate is 20%</p>\n",
                   format_content("The vat rate is [DataApi:4f8583b5e5a4e46a64000002]")
    end
  end
end
