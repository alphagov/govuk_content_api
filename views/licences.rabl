object false

node :_response_info do
  { status: "ok" }
end

node(:description) { "Licences" }
node(:total) { @results.count }
node(:start_index) { 1 }
node(:page_size) { @results.count }
node(:current_page) { 1 }
node(:pages) { 1 }

node(:results) do
  @results.map { |r|
    partial "_full_artefact", object: r
  }
end
