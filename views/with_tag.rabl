object false
node :response do
  {
    status: 'ok',
    description: "Search for your query",
    total: @results.count,
    startIndex: 1,
    pageSize: @results.count,
    currentPage: 1,
    pages: 1,
    results: @results.map { |r|
      basic = {
        id: r.slug,
        title: r.name,
        fields: {
	        tags: r.tag_ids,
          format: r.kind,
        }
      }

      if r.edition and r.edition.is_a?(AnswerEdition)
        basic[:fields][:overview] = r.edition.overview
        basic[:fields][:body] = r.edition.body
        basic[:fields][:alternative_title] = r.edition.alternative_title
      end

      basic
    }
  }
end

