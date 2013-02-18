extends "paginated"
object @result_set

node(:description) { @tag_type_name ? "All '#{@tag_type_name}' tags" : "All tags" }

child(:results => "results") do
  extends "_tag"
end
