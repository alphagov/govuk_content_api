extends "paginated"
object @result_set

node(:description) { "Licences" }

child(:results => "results") do
  extends "_basic_artefact"
  node :details do |artefact|
    {
      "licence_identifier" => artefact.edition.licence_identifier,
      "licence_short_description" => artefact.edition.licence_short_description,
    }
  end
end
