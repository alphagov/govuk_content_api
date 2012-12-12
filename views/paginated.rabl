node :_response_info do
  { status: "ok" }
end

attributes :total, :start_index, :page_size, :current_page, :pages

# Inheriting templates should put results into the "results" node
