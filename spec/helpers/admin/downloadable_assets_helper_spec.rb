require File.expand_path(File.dirname(__FILE__) + "../../../spec_helper")

describe Admin::DownloadableAssetsHelper do
  before(:all) do
    @asset = DownloadableAsset.create(:id => 123, :asset => File.new(Rails.root + 'spec/fixtures/images/wikileaks.jpg'))
    @prev_token_cdn_host = S3[:token_cdn_host]
    @prev_cdn_host = S3[:cdn_host]
    @prev_enabled_flag = S3[:enabled]
    @prev_bucket = S3[:bucket]
  end

  before(:each) do
    S3[:token_cdn_host] = 'cdn.getup.org.au'
    S3[:cdn_host] = 'blah.cloudfront.net'
    controller.request.host = 'my.test.host'
  end

  after(:each) do
    S3[:token_cdn_host] = @prev_token_cdn_host
    S3[:cdn_host] = @prev_cdn_host
    S3[:enabled] = @prev_enabled_flag
    S3[:bucket] = @prev_bucket
  end

  describe "#token_asset_url" do
    it "should provide the token url for the asset" do
      helper.token_asset_url(@asset).should == "http://#{S3[:token_cdn_host]}/#{@asset.name}"
    end
  end

  describe "#download_asset_link" do
    it "translates local paths to URLs" do
      S3[:enabled] = false
      link = helper.download_asset_link(@asset)
      link.should match("href=['|\"]http://my.test.host/system/#{@asset.id}-wikileaks.jpg['|\"]")
      link.should match("#{@asset.link_text}")
    end

    it "translates CDN paths to correct URLs" do
      S3[:enabled] = true
      S3[:bucket] = "xyz"
      link = helper.download_asset_link(@asset)
      link.should match("href=['|\"]http://#{S3[:cdn_host]}/#{@asset.id}-wikileaks.jpg['|\"]")
      link.should match("#{@asset.link_text}")
    end
  end
end
