extends "paginated"
object @result_set

node(:description) { "All tags" }

child(:results => "results") do
  extends "_tag"
end
