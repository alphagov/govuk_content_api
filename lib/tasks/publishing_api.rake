require 'logger'
require 'gds_api/publishing_api'
require 'gds_api/publishing_api/special_route_publisher'

namespace :publishing_api do
  desc 'Publish special routes via publishing api'

  task :publish_special_routes do
    publishing_api = GdsApi::PublishingApiV2.new(
      Plek.new.find('publishing-api'),
      bearer_token: ENV['PUBLISHING_API_BEARER_TOKEN'] || 'example'
    )

    special_route_publisher = GdsApi::PublishingApi::SpecialRoutePublisher.new(
      logger: Logger.new(STDOUT),
      publishing_api: publishing_api
    )

    special_route_publisher.publish(
      title: 'Public content API',
      description: 'The unsupported GOV.UK content API (https://insidegovuk.blog.gov.uk/2014/09/15/current-state-of-apis-on-gov-uk/)',
      content_id: '363a1f3a-5e80-4ff7-8f6f-be1bec62821f',
      base_path: '/api',
      type: 'prefix',
      publishing_app: 'govuk_content_api',
      rendering_app: 'publicapi'
    )
  end
end
