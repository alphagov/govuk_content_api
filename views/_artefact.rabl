node(:id) { |artefact| artefact_url(artefact) }
node(:web_url) { |artefact| artefact_web_url(artefact) }
attribute :name => :title
node(:details) { |artefact| partial("fields", object: artefact) }
node(:format, :if => lambda { |artefact| artefact.edition }) do |artefact| 
  artefact.edition.format
end

# Explicit naming here gives us an empty list if there are no tags
child :tags => :tags do
  extends "_tag"
end

child :related_artefacts => :related_artefacts do
  node(:id) { |a| artefact_url(a) }
  node(:web_url) { |a| artefact_web_url(a) }
  attribute :name => :title
end
