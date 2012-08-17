node do
  list_parts = []
  @artefact.edition.parts.each do |p|
    part = {
              id: p.slug,
              order: p.order,
              title: p.title,
              body: Govspeak::Document.new(p.body).to_html
            }
    list_parts.push(part)
  end
  return list_parts
end