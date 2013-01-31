class Country

  attr_reader :name, :slug
  attr_accessor :edition

  def initialize(attrs)
    @name = attrs['name']
    @slug = attrs['slug']
  end

  def editions
    TravelAdviceEdition.where(:country_slug => self.slug).order_by([:version_number, :desc])
  end

  def self.all
    @countries ||= data.map { |d| Country.new(d) }
  end

  def self.find_by_slug(slug)
    all.select {|c| c.slug == slug }.first
  end

  def self.data
    YAML.load_file(data_path)
  end

  # overridden in the tests to use a fixture with a smaller subset of data.
  def self.data_path
    @data_path ||= File.expand_path("../data/countries.yml", __FILE__)
  end

  def self.data_path=(path)
    @countries = nil if path != @data_path # Clear the memoized countries when the data_path is changed.
    @data_path = path
  end
end
