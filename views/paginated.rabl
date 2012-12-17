node :_response_info do |results|
  if results.respond_to? :links
    {
      "status" => "ok",
      "links" => (results.links || []).map do |link|
        { "href" => link.href }.merge(link.attrs)
      end
    }
  else
    {
      "status" => "ok"
    }
  end
end

attributes :total, :start_index, :page_size, :current_page, :pages

# Inheriting templates should put results into the "results" node
