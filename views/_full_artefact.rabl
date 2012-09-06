extends "_basic_artefact"

child :tags => :tags do
  extends "_tag"
end

child :related_artefacts => :related_artefacts do
  extends "_basic_artefact"
end