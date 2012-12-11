object false

node :_response_info do
  { status: "ok" }
end

node(:description) { "Tags!" }
node(:total) { @page_info.total_count }
node(:start_index) { @page_info.offset + 1 }
node(:page_size) { @page_info.limit_value }
node(:current_page) { @page_info.current_page }
node(:pages) { @page_info.total_pages }
node(:results) do
  @tags.map { |r|
    partial "_tag", object: r
  }
end
