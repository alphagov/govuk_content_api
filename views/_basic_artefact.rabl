node(:id) { |artefact| artefact_url(artefact) }
node(:web_url) { |artefact| artefact_web_url(artefact) }
attribute :name => :title
node(:details) { |artefact| partial("fields", object: artefact) }
node(:format, :if => lambda { |artefact| artefact.edition }) do |artefact| 
  artefact.edition.format
end

child :tags => :tags do
  extends "_tag"
end
