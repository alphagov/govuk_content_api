# Present a licence as retrieved from the licensing API and attached to an
# artefact (see the `attach_license_data` method in `govuk_content_api.rb`)
class ArtefactLicencePresenter
  def initialize(licence)
    @licence = licence
  end

  def present
    if @licence["error"]
      return { "error" => @licence["error"] }
    end

    presented = {
      "location_specific" => @licence["isLocationSpecific"],
      "availability" => @licence["geographicalAvailability"],
      "authorities" => authorities
    }.merge(local_service)
  end

private
  def authorities
    if @licence['issuingAuthorities']
      @licence['issuingAuthorities'].map {|authority|
        {
          'name' => authority['authorityName'],
          'slug' => authority['authoritySlug'],
          'contact' => authority['authorityContact'],
          'actions' => authority['authorityInteractions'].inject({}) {|actions, (key, links)|
            actions[key] = links.map {|link|
              {
                'url' => link['url'],
                'introduction' => link['introductionText'],
                'description' => link['description'],
                'payment' => link['payment']
              }
            }
            actions
          }
        }
      }
    else
      [ ]
    end
  end

  def local_service
    if @licence['local_service']
      { "local_service" => @licence["local_service"] }
    else
      {}
    end
  end
end
