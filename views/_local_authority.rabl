node(:id) { |authority| local_authority_url(authority) }
attribute :name
attribute :snac => :snac_code
attribute :tier
attribute :contact_address
attribute :contact_url
attribute :contact_phone
attribute :contact_email

