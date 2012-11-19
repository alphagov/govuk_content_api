extends "_basic_artefact"

node(:details) { |artefact| partial("fields", object: artefact) }

child :tags => :tags do
  extends "_tag"
end

child :live_related_artefacts => :related do
  extends "_basic_artefact"
end