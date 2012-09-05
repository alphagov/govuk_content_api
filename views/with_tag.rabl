object false

node :_response_info do
  { status: "ok" }
end

node(:description) { "Search for your query" }
node(:total) { @results.count }
node(:startIndex) { 1 }
node(:pageSize) { @results.count }
node(:currentPage) { 1 }
node(:pages) { 1 }

node(:results) do
  @results.map { |r|
    partial "_full_artefact", object: r
  }
end
