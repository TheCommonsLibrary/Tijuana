module Admin
  module DownloadableAssetsHelper
    def token_asset_url(asset)
      "http://#{S3[:token_cdn_host]}/#{asset.name}"
    end

    def download_asset_link(asset)
      link_to(asset.link_text, substitute_real_cdn_url(token_asset_url(asset)))
    end
  end
end
