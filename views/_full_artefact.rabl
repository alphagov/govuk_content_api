extends "_basic_artefact"

node(:details) { |artefact| partial("fields", object: artefact) }
