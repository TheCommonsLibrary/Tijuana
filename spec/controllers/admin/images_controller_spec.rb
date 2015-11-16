require File.expand_path(File.dirname(__FILE__) + "../../../spec_helper")

describe Admin::ImagesController do
  include Devise::TestHelpers # to give your spec access to helpers
  
  before :each do
    sign_in create(:admin_user)
  end

  describe "GET 'index'" do
    it "should be successful" do
      get 'index'
      response.should be_success
    end
  end

  describe "POST 'create'" do
    it "should upload/convert successfully" do
      @image = Image.create :image => File.new(Rails.root + 'spec/fixtures/images/wikileaks.jpg')
      Image.stub(:new).and_return(@image)
      post 'create', {"image"=>{}}
      assigns(:new_image).should eql(@image)
      response.should redirect_to(admin_image_path(@image))
    end
  end
end
