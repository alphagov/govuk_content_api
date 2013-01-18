extends "paginated"
object @result_set

node(:description) { @description }

node(:results) do
  @result_set.results.map { |r|
    partial "_full_artefact", object: r
  }
end
