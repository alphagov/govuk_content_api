node(:id) { |artefact| artefact_url(artefact) }
node(:web_url) { |artefact| artefact_web_url(artefact) }
attribute :name => :title
node(:format) do |artefact| 
  if artefact.edition 
    artefact.edition.format.underscore
  else
    artefact.kind
  end
end
node(:details) { |artefact| partial("fields", object: artefact) }
node(:updated_at) { |artefact|
  updated_options = [artefact.updated_at]
  updated_options << artefact.edition.updated_at if artefact.edition
  updated_options.compact.max.iso8601
}