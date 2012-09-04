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
    partial "_artefact", object: r
    # basic = {
    #   id: r.slug,
    #   title: r.name,
    #   details: {
    #     tags: r.tag_ids,
    #     format: r.kind,
    #   }
    # }

    # if r.edition and r.edition.is_a?(AnswerEdition)
    #   basic[:details][:overview] = r.edition.overview
    #   basic[:details][:body] = format_content(r.edition.body)
    #   basic[:details][:alternative_title] = r.edition.alternative_title
    # end

    # basic
  }
end
