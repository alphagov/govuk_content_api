require "test_helper"
require "govspeak_formatter"
require "gds_api/helpers"

describe GovspeakFormatter do

  describe "format" do
    include GdsApi::Helpers

    it "should convert govspeak to html" do
      formatter = GovspeakFormatter.new(:html)
      assert_equal(
        "<h1>GOVUK Govspeak</h1>\n\n<h2>Headings</h2>\n",
        formatter.format("# GOVUK Govspeak\n\n## Headings")
      )
    end

    it "should add automatic header ids when requested" do
      formatter = GovspeakFormatter.new(:html, auto_ids: true)
      assert_equal(
        %Q{<h2 id="govspeak">Govspeak</h2>\n},
        formatter.format("## Govspeak")
      )
    end

    it "should return unformatted govspeak when requested" do
      formatter = GovspeakFormatter.new(:govspeak)
      assert_equal(
        "# GOVUK Govspeak\n\n## Headings",
        formatter.format("# GOVUK Govspeak\n\n## Headings")
      )
    end
  end
end
