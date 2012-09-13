node do |artefact|
  list_parts = []
  artefact.edition.parts.each do |p|
    part = {
              id: artefact_part_web_url(artefact, p),
              order: p.order,
              title: p.title,
              body: format_content(p.body)
            }
    list_parts.push(part)
  end
  return list_parts
end