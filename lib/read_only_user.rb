require 'gds-sso/user'

class ReadOnlyUser < OpenStruct
  def self.attr_accessible(*args)
  end

  include GDS::SSO::User

  def self.find_by_uid(uid)
    nil
  end

  # For compatibility with https://github.com/alphagov/gds-sso/commit/9f2ae189117eca1758dea108923d15c6fe2b7de7
  def self.where(uid)
    []
  end

  def self.create!(auth_hash, options={})
    ReadOnlyUser.new(auth_hash)
  end

  def update_attribute(*args)
  end
end
