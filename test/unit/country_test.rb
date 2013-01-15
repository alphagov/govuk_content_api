require_relative "../test_helper"
require 'country'

describe Country do
  describe "Country.all" do
    it "should return a list of Countries" do
      assert_equal 14, Country.all.size
      assert_equal "Afghanistan", Country.all.first.name
      assert_equal "afghanistan", Country.all.first.slug
      assert_equal "Argentina", Country.all.find { |c| c.slug == "argentina" }.name
    end
  end

  describe "Country.find_by_slug" do
    it "returns a Country given a valid slug" do
      country = Country.find_by_slug('argentina')

      assert_equal Country, country.class
      assert_equal "argentina", country.slug
      assert_equal "Argentina", country.name
    end

    it "returns nil given an invalid slug" do
      country = Country.find_by_slug('wibble')

      assert_equal nil, country
    end
  end

  describe "finding editions for a country" do
    before do
      @country = Country.all.first
    end

    it "should return all TravelAdviceEditions with the matching country_slug" do
      e1 = FactoryGirl.create(:travel_advice_edition, :state => 'archived', :country_slug => @country.slug)
      e2 = FactoryGirl.create(:travel_advice_edition, :state => 'archived', :country_slug => "wibble")
      e3 = FactoryGirl.create(:travel_advice_edition, :state => 'archived', :country_slug => @country.slug)

      assert_equal [e1, e3].sort, @country.editions.to_a.sort
    end

    it "should order them by descending version_number" do
      e1 = FactoryGirl.create(:travel_advice_edition, :state => 'archived', :country_slug => @country.slug, :version_number => 1)
      e3 = FactoryGirl.create(:travel_advice_edition, :state => 'archived', :country_slug => @country.slug, :version_number => 3)
      e2 = FactoryGirl.create(:travel_advice_edition, :state => 'archived', :country_slug => @country.slug, :version_number => 2)

      assert_equal [e3, e2, e1], @country.editions.to_a
    end
  end
end
