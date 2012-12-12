require "kaminari"
require "kaminari/models/mongoid_extension"
require "govuk_content_models/require_all"

# The default number of items on a single page is based on the maximum number
# of subsections we would expect to find within a section, and the maximum
# number of artefacts we would expect to find within a subsection, with a bit
# of padding on the end.
#
# If there is a need, we can provide the ability to override this, either at
# deployment time or (with appropriate controls) based on a query parameter.
Kaminari.configure do |config|
  config.default_per_page = 30
end

# Models imported from a gem don't seem to get the Mongoid patch applied to
# them <https://github.com/amatsuda/kaminari/issues/213>, so we need to include
# the Kaminari extensions into the models manually.
#
# See also: <http://stackoverflow.com/questions/12747690/>

paginated_models = [Tag, Artefact]

paginated_models.each do |model|
  model.send :include, Kaminari::MongoidExtension::Criteria
  model.send :include, Kaminari::MongoidExtension::Document
end
