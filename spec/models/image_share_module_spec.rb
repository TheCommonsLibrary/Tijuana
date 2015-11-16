require File.expand_path(File.dirname(__FILE__) + "../../spec_helper")

describe ImageShareModule do  
  
  before(:each) do
    @user = create(:user)
    @image_share = create(:image_share_module)
    @page = create(:page_with_parent)
  end
  describe "taking action" do

    it "should save an image share action" do
      @image_share.update_action_attributes_and_validate({caption: 'caption'})
      @image_share.take_action(@user, @page)
      image_share = @image_share.take_action(@user, @page)
      image_share.should be_an_instance_of ImageShare
      image_share.should be_valid
      image_share.should be_persisted
    end
    
    it "should create a user activity event without an email reference" do
      UserActivityEvent.should_receive(:action_taken!).with(@user, @page, @image_share, an_instance_of(ImageShare), nil, nil, nil)
      @image_share.update_action_attributes_and_validate({caption: 'caption'})
      @image_share.take_action(@user, @page)
    end

    it "should create a user activity event with an email reference" do
      @email = create(:email)
      UserActivityEvent.should_receive(:action_taken!).with(@user, @page, @image_share, an_instance_of(ImageShare), @email, nil, nil)
      @image_share.update_action_attributes_and_validate({caption: 'caption'})
      @image_share.take_action(@user, @page, @email)
    end
  end
  
  
  describe "handling duplicates" do
    it "should allow duplicates" do
      image_share = create(:image_share_module)
      image_share.update_action_attributes_and_validate({caption: 'caption'})
      image_share.take_action(@user, @page)

      image_share = create(:image_share_module)
      image_share.update_action_attributes_and_validate({caption: 'caption'})
      image_share.take_action(@user, @page)
      ImageShare.where(user_id: @user.id, page_id: @page.id).count.should == 2
    end
  end

end
