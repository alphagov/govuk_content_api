module Services
  def self.asset_manager
    @asset_manager ||= GdsApi::AssetManager.new(
      Plek.current.find('asset-manager'),
      bearer_token: ENV['ASSET_MANAGER_BEARER_TOKEN']
    )
  end
end
