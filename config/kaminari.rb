require "kaminari"
require "kaminari/models/mongoid_extension"
require "govuk_content_models/require_all"

# Models imported from a gem don't seem to get the Mongoid patch applied to
# them <https://github.com/amatsuda/kaminari/issues/213>, so we need to include
# the Kaminari extensions into the models manually.
#
# See also: <http://stackoverflow.com/questions/12747690/>

paginated_models = [Tag]

paginated_models.each do |model|
  model.send :include, Kaminari::MongoidExtension::Criteria
  model.send :include, Kaminari::MongoidExtension::Document
end
