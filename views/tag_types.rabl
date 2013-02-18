extends "paginated"
object @result_set

node(:description) { "All tag types" }

child(:results => "results") do
  attributes :type, :id, :total
end
