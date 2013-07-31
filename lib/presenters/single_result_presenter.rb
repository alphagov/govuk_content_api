class SingleResultPresenter
  # Presents a single result, with attached response information

  def initialize(result_presenter)
    @result_presenter = result_presenter
  end

  def present
    @result_presenter.present.merge(
      { "_response_info" => { "status" => "ok" } }
    )
  end
end
