require "test_helper"
require "tag_types"

class TagTypesTest < MiniTest::Spec

  describe "TagTypes" do
    it "returns a type from its plural" do
      types = TagTypes.new(["badgers", "carrots"])
      t = types.from_plural("badgers")
      assert_equal "badgers", t.plural
      assert_equal "badger", t.singular
    end

    it "returns a type from its singular" do
      types = TagTypes.new(["badgers", "carrots"])
      t = types.from_singular("badger")
      assert_equal "badgers", t.plural
      assert_equal "badger", t.singular
    end

    it "returns nil for an unknown type" do
      types = TagTypes.new(["badgers", "carrots"])
      assert_nil types.from_plural("onions")
    end

    it "returns immutable values" do
      types = TagTypes.new(["badgers", "carrots"])
      t = types.from_plural("badgers")
      assert_raises NoMethodError do t.plural = "pies" end
      assert_raises NoMethodError do t.singular = "pie" end
    end
  end
end

