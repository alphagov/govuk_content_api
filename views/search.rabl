object false

node :_response_info do
  { status: "ok" }
end

node(:total) { @results.count }
node(:start_index) { 1 }
node(:page_size) { @results.count }
node(:current_page) { 1 }
node(:pages) { 1 }

node(:results) do
  @results.map { |r|
    {
      id: search_result_url(r),
      web_url: search_result_web_url(r),
      title: r['title'],
      details: {
        description: r['description']
      }
    }
  }
end
