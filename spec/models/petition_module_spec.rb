require File.expand_path(File.dirname(__FILE__) + "../../spec_helper")

describe PetitionModule do  
        
  def validated_petition_module(attrs)
    pm = create(:petition_module)
    pm.update_attributes attrs
    pm.valid?
    pm
  end
  
  describe "validation" do
    it "should require a title between 3 and 128 characters" do
      validated_petition_module(:title => "Save the kittens!").should be_valid
      validated_petition_module(:title => "X" * 128).should be_valid
      validated_petition_module(:title => "X" * 129).should_not be_valid
      validated_petition_module(:title => "AB").should_not be_valid
    end

    it "should require a button text between 1 and 64 characters" do
      validated_petition_module(:button_text => "Save the kittens!").should be_valid
      validated_petition_module(:button_text => "X" * 64).should be_valid
      validated_petition_module(:button_text => "X" * 65).should_not be_valid
      validated_petition_module(:button_text => "").should_not be_valid
    end
    
    it "should require a target greater than or equal to 0" do
       validated_petition_module(:signatures_target => 1).should be_valid
       validated_petition_module(:signatures_target => 0).should be_valid
       validated_petition_module(:signatures_target => nil).should_not be_valid
    end

    it "should require a thermometer threshold greater than or equal to 0" do
       validated_petition_module(:thermometer_threshold => 1).should be_valid
       validated_petition_module(:thermometer_threshold => 0).should be_valid
       validated_petition_module(:thermometer_threshold => nil).should_not be_valid
    end
    
    it "should require a petition statement" do
      validated_petition_module(:button_text => "Save the kittens!").should be_valid
      validated_petition_module(:button_text => "X" * 64).should be_valid
      validated_petition_module(:button_text => "").should_not be_valid
    end
  end
  
  describe "taking action" do
    include VanityTestHelper

    before(:each) do
      @user = create(:user)
      @pm = create(:petition_module)
      @page = create(:page_with_parent)
      setup_fake_context
      @experiment = Vanity.playground.experiment(:sign_with_fb)
      @experiment.identify { |controller| 1 }
    end
    it "should save a petition signature" do
      signature = @pm.take_action(@user, @page)
      signature.should be_an_instance_of PetitionSignature
      signature.should be_valid
      signature.should be_persisted
    end
    
    it "should create a user activity event without an email reference" do
      UserActivityEvent.should_receive(:action_taken!).with(@user, @page, @pm, an_instance_of(PetitionSignature), nil, an_instance_of(String), nil)
      @pm.take_action(@user, @page)
    end

    it "should create a user activity event with an email reference" do
      @email = create(:email)
      UserActivityEvent.should_receive(:action_taken!).with(@user, @page, @pm, an_instance_of(PetitionSignature), @email, an_instance_of(String), nil)
      @pm.take_action(@user, @page, @email)
    end


    context "with sign_with_facebook disabled" do
      it "should create a user activity event with an email reference" do
        @pm.sign_with_facebook = nil
        @email = create(:email)
        UserActivityEvent.should_receive(:action_taken!).with(@user, @page, @pm, an_instance_of(PetitionSignature), @email, nil, nil)
        @pm.take_action(@user, @page, @email)
      end
    end
    
    it "Should track take action analytics event" do
      @pm.flash = ActionDispatch::Flash::FlashHash.new
      @pm.take_action(@user, @page)
      @pm.analytics_events_js.should include "ga('send', 'event', 'petition module', 'action taken', '', 1);"
    end
  end
  
  describe "calculating percentage" do
    before(:each) do
      @page = create(:page_with_parent)
      @user = create(:user)
    end
    
    it "should know how many signatures have been collected" do
      petition = create(:petition_module, :signatures_target => 10)
      3.times { |i| create(:petition_signature, :content_module => petition, :page => @page, :user => @user) }
      
      petition.signatures.should == 3
    end
    
    it "should correctly calculate the percentage complete truncated to the nearest percent" do
      m1 = create(:petition_module, :signatures_target => 10)
      3.times { |i| create(:petition_signature, :page => @page, :content_module => m1, :user => @user) }

      m1.percentage_complete.should == 30
    end
  end
  
  describe "handling duplicates" do
    it "should raise an error if the ask/user combo has been seen before" do
      user = create(:user, :email => 'noone@example.com')
      ask = create(:petition_module)
      ask.take_action(user, create(:page_with_parent)).save!
      expect { ask.take_action(user, create(:page_with_parent)) }.to raise_error(DuplicateActionTakenError)
    end

    it "should allow duplicate if custom 'allow_duplicates' is true" do
      user = create(:user, :email => 'noone@example.com')
      ask = create(:petition_module, custom_fields: {allow_duplicates: true})
      page = create(:page_with_parent)
      ask.take_action(user, page).save!

      same_ask = PetitionModule.find(ask.id) # can't use 'ask' as petition signature hangs around
      lambda {
        same_ask.take_action(user, page).save!
      }.should change(PetitionSignature, :count).by(1)
    end
  end

  describe '#display_sign_with_facebook?' do
    before :each do
      @petition_module = create(:petition_module)
    end

    it 'should be true by default' do
      @petition_module.display_sign_with_facebook?.should be true
    end

    it 'should return true if sign_with_facebook option field is checked' do
      @petition_module.sign_with_facebook = '1'
      @petition_module.display_sign_with_facebook?.should be true
    end

    it 'should return false if sign_with_facebook option field is unchecked' do
      @petition_module.sign_with_facebook = '0'
      @petition_module.display_sign_with_facebook?.should_not be true
    end
  end

  describe '#fb_app_id' do
    before :each do
      @petition_module = create(:petition_module)
    end

    it 'should return AppConstants FB App ID when undefined' do
      @petition_module.facebook_app_id = nil
      @petition_module.fb_app_id.should == AppConstants.facebook_sign_petition_module_app_id
    end

    it 'should return configured FB App ID' do
      @petition_module.facebook_app_id = '11111'
      @petition_module.fb_app_id.should == '11111'
    end
  end
end
