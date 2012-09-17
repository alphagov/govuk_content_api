node(:id) { |artefact| artefact_url(artefact) }
node(:web_url) { |artefact| artefact_web_url(artefact) }
attribute :name => :title
attribute :kind
node(:details) { |artefact| partial("fields", object: artefact) }
