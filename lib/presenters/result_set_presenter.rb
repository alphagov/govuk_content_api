class ResultSetPresenter
  # Presents a paginated (or fake-paginated) result set.
  #
  # This class assumes it will receive a PaginatedResultSet object (or one with
  # the same pagination and `results` methods on it), a URLHelper instance and
  # a class it can use to build a presenter for each individual result.
  #
  # The presenter class should take a result (whatever shape that may take) and
  # the URLHelper instance in its initialiser, and provide a `present` method.

  def initialize(result_set, url_helper, result_presenter_class, options = {})
    @result_set = result_set
    @url_helper = url_helper
    @result_presenter_class = result_presenter_class
    @description = options[:description]
  end

  def present
    paginated_response_base.merge(
      "results" => @result_set.results.map do |result|
        @result_presenter_class.new(result, @url_helper).present
      end
    )
  end

  private
  def paginated_response_base
    presented = {
      "_response_info" => {
        "status" => "ok",
        "links" => links
      }
    }

    presented["description"] = @description if @description

    [:total, :start_index, :page_size, :current_page, :pages].each do |key|
      presented[key.to_s] = @result_set.send(key)
    end

    presented
  end

  def links
    @result_set.links.map do |link|
      { "href" => link.href }.merge(link.attrs)
    end
  end
end
