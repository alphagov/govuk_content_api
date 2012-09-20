node(:location_specific) {|artefact| artefact.licence['isLocationSpecific'] }
node(:availability) {|artefact| artefact.licence['geographicalAvailability'] }

node(:authorities) do |artefact|
  if artefact.licence['issuingAuthorities']
    artefact.licence['issuingAuthorities'].map {|authority|
      {
        'name' => authority['authorityName'],
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