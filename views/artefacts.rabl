extends "paginated"
object @result_set

child(:results => "results") do
  node(:id) { |a| artefact_url(a) }
  node(:web_url) { |a| artefact_web_url(a) }
  attributes :kind => :format, :name => :title
end
