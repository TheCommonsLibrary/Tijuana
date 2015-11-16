require File.expand_path(File.dirname(__FILE__) + "../../spec_helper")

describe UsersHelper do

  describe "#display_name" do

    before(:each) do
      @page = Page.new
    end

    it "should generate titlecase display name from field name" do
      helper.display_name(@page, :first_name).should == "First Name"
    end

    it "should allow custom display name" do
      helper.display_name(@page, :last_name, false, 'Surname').should == "Surname"
    end

    it "should include asterisk when asked for required and refresh fields" do
      @page.required_user_details = {:first_name => "required"}
      helper.display_name(@page, :first_name).should == "First Name*"

      @page.required_user_details = {:first_name => "refresh"}
      helper.display_name(@page, :first_name).should == "First Name*"
    end

    it "should not include asterisk when not requested" do
      @page.required_user_details = {:first_name => "required"}
      helper.display_name(@page, :first_name, false).should == "First Name"
    end
  end

  describe "#user_details_class" do
    before(:each) do
      @page = Page.new
    end

    it "should return nothing when not required" do
      helper.user_details_class(@page, :first_name).should be_blank
    end

    it "should return 'required' if the field is set to refresh or required" do
      @page.required_user_details = {:first_name => "refresh"}
      helper.user_details_class(@page, :first_name).should == 'required'

      @page.required_user_details = {:first_name => "required"}
      helper.user_details_class(@page, :first_name).should == 'required'
    end

    it "should return the specified class as well as the any required class" do
      helper.user_details_class(@page, :first_name, 'my-class').should == 'my-class'

      @page.required_user_details = {:first_name => "required"}
      helper.user_details_class(@page, :first_name, 'something').should match(/required/)
      helper.user_details_class(@page, :first_name, 'something').should match(/something/)
    end
  end

  describe "quick_donate_card_info" do
    it "should return card info of original donation for user with quickdonate" do
      create(:donation, payment_method: 'credit_card', card_number: '378734493671000', trigger_id: 'MY_TRIGGER_ID')
      user = create(:user, quick_donate_trigger_id: 'MY_TRIGGER_ID')
      quick_donate_card_info(user).should include 'American Express: ****1000'
    end
    it "should return card info if card type not known" do
      create(:donation, payment_method: 'credit_card', card_number: '0000444444444448', trigger_id: 'MY_TRIGGER_ID')
      user = create(:user, quick_donate_trigger_id: 'MY_TRIGGER_ID')
      quick_donate_card_info(user).should include 'Credit Card: ****4448'
    end
    it "should return nil if no quickdonate_trigger_id set" do
      create(:donation, payment_method: 'credit_card', card_number: '378734493671000', trigger_id: nil)
      user = create(:user, quick_donate_trigger_id: nil)
      quick_donate_card_info(user).should be_nil
    end
  end

end
