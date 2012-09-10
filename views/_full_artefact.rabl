extends "_basic_artefact"

child :tags => :tags do
  extends "_tag"
end

child :related_artefacts => :related do
  extends "_basic_artefact"
end