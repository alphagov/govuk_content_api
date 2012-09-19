object false

node :_response_info do
  { 
    status: "ok",
    env: env.inspect,
    request: request.inspect
  }
end

node(:description) { "Tags!" }
node(:total) { @tags.count }
node(:startIndex) { 1 }
node(:pageSize) { @tags.count }
node(:currentPage) { 1 }
node(:pages) { 1 }
node(:results) do
  @tags.map { |r|
    partial "_tag", object: r
  }
end
