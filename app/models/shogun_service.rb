class ShogunService
  include HTTParty
  base_uri SHOGUN_BASE_URI

  def self.harvest(catalog_url)
    options = { query: { url: catalog_url } }
    post('/v1/harvest', options)
  end
end
