class ResultSetPresenter

  # Default class to use as a result presenter, so we can use the same code
  # whether we're providing a custom presenter or not.
  class DummyResultPresenter
    def initialize(result)
      @result = result
    end

    def present
      @result
    end
  end

  def initialize(result_set, create_result_presenter = DummyResultPresenter)
    @result_set = result_set

    if create_result_presenter.is_a? Class
      @create_result_presenter = lambda { |x| create_result_presenter.new(x) }
    else
      @create_result_presenter = create_result_presenter
    end
  end

  def present
    presented = {
      "_response_info" => { "status" => "ok" }
    }

    [:total, :start_index, :page_size, :current_page, :pages].each do |key|
      presented[key.to_s] = @result_set.send(key)
    end

    presented["results"] = @result_set.results.map do |result|
      @create_result_presenter.call(result).present
    end

    presented
  end
end
