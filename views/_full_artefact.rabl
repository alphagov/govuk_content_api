extends "_basic_artefact"

child :tags => :tags do
  extends "_tag"
end

child :live_related_artefacts => :related do
  extends "_basic_artefact"
end