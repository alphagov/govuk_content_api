object false

node :_response_info do
  { status: "ok" }
end

node(:description) { "Tags!" }
node(:total) { @tags.count }
node(:start_index) { 1 }
node(:page_size) { @tags.count }
node(:current_page) { 1 }
node(:pages) { 1 }
node(:results) do
  @tags.map { |r|
    partial "_tag", object: r
  }
end
