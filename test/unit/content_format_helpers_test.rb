require "test_helper"
require "content_format_helpers"
require "gds_api/test_helpers/fact_cave"
require "mocha"

class ContentFormatHelpersTest < MiniTest::Spec

  include ContentFormatHelpers
  include GdsApi::TestHelpers::FactCave

  describe "process_content" do
    it "should convert govspeak to html" do
      self.stubs(:params).returns({})
      assert_equal "<h1>GOVUK Govspeak</h1>\n\n<h2>Headings</h2>\n", process_content("# GOVUK Govspeak\n\n## Headings")
    end

    it "should return unformatted govspeak when requested" do
      self.stubs(:params).returns({:content_format => 'govspeak'})
      assert_equal "# GOVUK Govspeak\n\n## Headings", process_content("# GOVUK Govspeak\n\n## Headings")
    end

    it "should interpolate fact values into content when requested as govspeak" do
      fact_cave_has_a_fact('vat-rate', {:id => 'vat-rate', :title => 'VAT rate', :details => { :value => '20%' }})
      self.stubs(:params).returns({:content_format => 'govspeak'})
      assert_equal "## The current VAT rate is 20%", process_content("## The current VAT rate is [Fact:vat-rate]")
    end

    it "should interpolate fact values into content and format govspeak" do
      fact_cave_has_a_fact('vat-rate', {:id => 'vat-rate', :title => 'VAT rate', :details => { :value => '20%' }})
      fact_cave_has_a_fact('pi-2-decimal-places',
                           {:id => 'pi-2-decimal-places', :title => 'PI to 2 decimal places', :details => { :value => '3.14' }})
      self.stubs(:params).returns({})
      assert_equal "<p><em>The current VAT rate is 20%, PI is approx. 3.14</em></p>\n",
        process_content("*The current VAT rate is [Fact:vat-rate], PI is approx. [Fact:pi-2-decimal-places]*")
    end

    it "should replace fact content markers with an empty string where no value exists" do
      fact_cave_does_not_have_a_fact('foo')
      self.stubs(:params).returns({})
      assert_equal "<p>The value of foo is </p>\n", process_content("The value of foo is [Fact:foo]")
    end
  end
end
