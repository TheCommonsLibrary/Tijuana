require File.expand_path(File.dirname(__FILE__) + "../../../spec_helper")

describe Admin::ImagesHelper do
  before(:all) do
    @image = Image.create(:id => 123, 
                          :image => File.new(Rails.root + 'spec/fixtures/images/wikileaks.jpg'))
    @prev_enabled = S3[:enabled]
    @prev_bucket = S3[:bucket]
  end

  after(:each) do
    S3[:enabled] = @prev_enabled
    S3[:bucket] = @prev_bucket
  end

  before(:each) { controller.request.host = 'my.test.host' }

  describe "#token_image_url" do
    it "translates image paths to token paths" do
      S3[:enabled] = true
      S3[:bucket] = "xyz"
      helper.token_image_url(@image, :thumbnail).should eql("http://cdn.getup.org.au/image_#{@image.id}_thumbnail.jpg")
      helper.token_image_url(@image, :original).should eql("http://cdn.getup.org.au/image_#{@image.id}_original.jpg")
      helper.token_image_url(@image).should eql("http://cdn.getup.org.au/image_#{@image.id}_original.jpg")
    end
  end

  def provides_hosted_img_tag_with_real_url(img_url)
    helper.hosted_image_tag(@image).should match(img_url)
    tag = helper.hosted_image_tag(@image, {"class" => "my-class"})
    tag.should match(img_url)
    tag.should match('class=[\'|"]my-class[\'|"]')
  end

  describe "#hosted_image_tag" do
    context "HTTP only" do
      context "S3 disabled" do
        specify { provides_hosted_img_tag_with_real_url("http://my.test.host/system/image_#{@image.id}_full.jpg") }
      end

      context "S3 enabled" do
        before(:each) do
          S3[:enabled] = true
          S3[:cdn_host] = "proudfront.net"
        end

        specify { provides_hosted_img_tag_with_real_url("http://proudfront.net/image_#{@image.id}_full.jpg") }
      end
    end

    context "with HTTPS" do
      before(:each) { controller.request.env['HTTPS'] = 'on' }
      after(:each) { controller.request.env['HTTPS'] = 'off' }

      context "S3 disabled" do
        specify { provides_hosted_img_tag_with_real_url("https://my.test.host/system/image_#{@image.id}_full.jpg") }
      end

      context "S3 enabled" do
        before(:each) do
          S3[:enabled] = true
          S3[:cdn_host] = "proudfront.net"
        end

        specify { provides_hosted_img_tag_with_real_url("https://proudfront.net/image_#{@image.id}_full.jpg") }
      end
    end

    it "provides a hosted image tag with the token URL" do
      helper.hosted_image_tag(@image, {}, false).should match("http://cdn.getup.org.au/image_#{@image.id}_full.jpg")
      tag = helper.hosted_image_tag(@image, {"class" => "my-class"}, false)
      tag.should match("http://cdn.getup.org.au/image_#{@image.id}_full.jpg")
      tag.should match('class=[\'|"]my-class[\'|"]')
    end
  end

  it "should provide detailed image information" do
    info = image_info(@image)
    info["Image URL"].should == "http://cdn.getup.org.au/image_#{@image.id}_full.jpg"
    info["Original URL"].should == "http://cdn.getup.org.au/image_#{@image.id}_original.jpg"
    info["Thumbnail URL"].should == "http://cdn.getup.org.au/image_#{@image.id}_thumbnail.jpg"
    info["Image type"].should == @image.image_content_type
    info["File Size"].should == '27.8 KB (28432 bytes)'
    info["Dimensions"].should == '512 x 288 pixels (width x height)'
  end
end
