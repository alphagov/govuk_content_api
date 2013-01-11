extends "paginated"
object @result_set

node(:description) { "Local Authorities" }
child(:results => "results") do
  extends "_local_authority"
end
