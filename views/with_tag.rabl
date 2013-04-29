extends "paginated"
object @result_set

node(:description) { @description }

child(:results => "results") do
  extends "_basic_artefact"
  node :details do |artefact|
    {
      "description" => artefact.description,
    }
  end
end
