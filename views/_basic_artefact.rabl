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
