# A collection of tag types, accessible by singular or plural name.
#
# This is really just a simple wrapper to avoid having to call inflector
# methods multiple times, and to pull out common logic to avoid peppering the
# controller code with inflector methods.
#
# Example usage:
#
#   types = TagTypes.new ["sections", "keywords", "badgers"]
#   tag_type = types.from_plural "badgers"
#   tag_type.singular
class TagTypes
  def initialize(plurals)
    @types = plurals.map { |p| TagType.new(p.singularize, p) }
  end

  def from_plural(plural)
    @types.find { |t| t.plural == plural }
  end

  def from_singular(singular)
    @types.find { |t| t.singular == singular }
  end
end

class TagType
  attr_reader :singular, :plural

  def initialize(singular, plural)
    @singular, @plural = singular, plural
  end
end

