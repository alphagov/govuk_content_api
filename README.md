## TODO

* Rest of content API methods from across GDS apps:
  * publisher: /local_transactions/verify_snac
  * publisher: /licenses
  * publisher: /publications/local-transaction.json?snac={snac}
  * publisher: /publications/local-transaction.json?all=1
  * imminence: /data_sets/public_bodies.json
  * imminence: /data_sets/writing_teams.json
  * imminence: /places/{service_id}?max_distance=?&limit=?&version=?
  * contact-o-tron

* Database error handling
* See if the solr code can be simplified
* Include details of publications other than answers
* Clean way to add more publication types
* Include related items
* Include curated lists
* Restructure gds_content_models so that require works better
* Can we decouple gds_content_models from gds-sso so we don't need to pull in rails?