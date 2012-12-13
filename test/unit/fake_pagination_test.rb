require "test_helper"
require "pagination"

class FakePaginationTest < MiniTest::Spec

  include Pagination

  describe "FakePaginatedResultSet" do
    it "gives the appropriate response when given an array" do
      p = FakePaginatedResultSet.new([1, 2, 3, 4, 5])

      assert_equal [1, 2, 3, 4, 5], p.results
      assert_equal 5, p.total
      assert_equal 1, p.start_index
      assert_equal 1, p.total_pages
      assert_equal 5, p.page_size
    end

    it "works with empty arrays" do
      p = FakePaginatedResultSet.new([])

      assert_equal [], p.results
      assert_equal 0, p.total
      assert_equal 1, p.start_index
      assert_equal 1, p.total_pages
      assert_equal 0, p.page_size
    end
  end
end

