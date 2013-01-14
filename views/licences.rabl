extends "paginated"
object @result_set

node(:description) { "Licences" }

child(:results => "results") do
  extends "_full_artefact"
end
