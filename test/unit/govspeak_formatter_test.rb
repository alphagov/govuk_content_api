require "test_helper"
require "govspeak_formatter"
require "gds_api/helpers"
require "gds_api/test_helpers/fact_cave"

describe GovspeakFormatter do

  describe "format" do
    include GdsApi::Helpers
    include GdsApi::TestHelpers::FactCave

    def empty_fact_cave
      stub("empty fact cave") do
        stubs(:fact).returns(nil)
      end
    end

    it "should convert govspeak to html" do
      formatter = GovspeakFormatter.new(:html, empty_fact_cave)
      assert_equal(
        "<h1>GOVUK Govspeak</h1>\n\n<h2>Headings</h2>\n",
        formatter.format("# GOVUK Govspeak\n\n## Headings")
      )
    end

    it "should add automatic header ids when requested" do
      formatter = GovspeakFormatter.new(:html, empty_fact_cave, auto_ids: true)
      assert_equal(
        %Q{<h2 id="govspeak">Govspeak</h2>\n},
        formatter.format("## Govspeak")
      )
    end

    it "should return unformatted govspeak when requested" do
      formatter = GovspeakFormatter.new(:govspeak, empty_fact_cave)
      assert_equal(
        "# GOVUK Govspeak\n\n## Headings",
        formatter.format("# GOVUK Govspeak\n\n## Headings")
      )
    end

    it "should interpolate fact values into content when requested as govspeak" do
      fact_cave_has_a_fact('vat-rate', '20%')
      formatter = GovspeakFormatter.new(:govspeak, fact_cave_api)
      assert_equal(
        "## The current VAT rate is 20%",
        formatter.format("## The current VAT rate is [fact:vat-rate]")
      )
    end

    it "should interpolate fact values into content and format govspeak" do
      fact_cave_has_a_fact('vat-rate', '20%')
      fact_cave_has_a_fact('pi-2-decimal-places', '3.14')

      formatter = GovspeakFormatter.new(:html, fact_cave_api)
      assert_equal(
        "<p><em>The current VAT rate is 20%, PI is approx. 3.14</em></p>\n",
        formatter.format("*The current VAT rate is [Fact:vat-rate], PI is approx. [Fact:pi-2-decimal-places]*")
      )
    end

    it "should replace fact content markers with an empty string where no value exists" do
      fact_cave_does_not_have_a_fact('foo')
      formatter = GovspeakFormatter.new(:html, fact_cave_api)
      assert_equal(
        "<p>The value of foo is </p>\n",
        formatter.format("The value of foo is [Fact:foo]")
      )
    end

    it "should interpolate formatted fact values into content" do
      test_date = Date.new(2013, 9, 24)
      fact_cave_has_a_fact('some-date', test_date, :type => :date)

      formatter = GovspeakFormatter.new(:html, fact_cave_api)
      assert_equal(
        "<p>Some date is 24 September 2013 okay.</p>\n",
        formatter.format("Some date is [Fact:some-date] okay.")
      )
    end
  end
end
