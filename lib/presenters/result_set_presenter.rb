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

  def initialize(result_set, result_presenter_class = DummyResultPresenter)
    @result_set = result_set
    @result_presenter_class = result_presenter_class
  end

  def present
    presented = {
      "_response_info" => { "status" => "ok" }
    }

    [:total, :start_index, :page_size, :current_page, :pages].each do |key|
      presented[key.to_s] = @result_set.send(key)
    end

    presented["results"] = @result_set.results.map do |result|
      @result_presenter_class.new(result).present
    end

    presented
  end
end
