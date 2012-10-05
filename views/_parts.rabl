node do |artefact|
  list_parts = []
  artefact.edition.order_parts.each do |p|
    part = {
              web_url: artefact_part_web_url(artefact, p),
              slug: p.slug,
              order: p.order,
              title: p.title,
              body: format_content(p.body)
            }
    list_parts.push(part)
  end
  return list_parts
end