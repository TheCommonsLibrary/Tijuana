require File.expand_path(File.dirname(__FILE__) + "../../spec_helper")

describe QuickdonateHelper do
  let(:quick_donor) { create(:user, quick_donate_trigger_id: "quick_donor") }
  let(:donation) { create(:donation, user: quick_donor) }

  before :each do
    session[:action_id] = donation.id
  end

  describe "#preceding_donation" do
    it "should return the donation that just occurred" do
      preceding_donation.should == donation
    end
  end

  describe "#just_donated_user" do
    it "should return the user who has just donated" do
      just_donated_user.should == donation.user
    end
  end

  describe "#enrolled_to_quick_donate?" do
    it "should return true if user enrolled" do
      enrolled_to_quick_donate?.should be true
    end

    it "should return false if user not enrolled" do
      just_donor = create(:user)
      donation = create(:donation, user: just_donor)
      session[:action_id] = donation.id

      enrolled_to_quick_donate?.should be false
    end
  end

  describe "#enable_quickdonate_cookie_for" do
    it "should set quick_donate_user_id session for given user" do
      helper.enable_quickdonate_cookie_for(donation.user)
      cookies.signed[:quick_donate_user_id].should == donation.user.id
    end

    it "cookies permanent, signed, secure and httponly" do
      permanent, signed = double(), double()
      cookies.should_receive(:permanent).once.and_return(permanent)
      permanent.should_receive(:signed).once.and_return(signed)
      signed.should_receive(:[]=).with(:quick_donate_user_id, {value: donation.user.id, secure: true, httponly: true})
      helper.enable_quickdonate_cookie_for(donation.user)
    end
  end

  describe "#quickdonate_cookie_for?" do
    it "should return true if cookie is set for user" do
      helper.enable_quickdonate_cookie_for(donation.user)
      helper.should be_quickdonate_cookie_for(donation.user)
    end
  end

  describe "#quickdonate_cookie?" do
    it "should return true if cookie is set" do
      helper.enable_quickdonate_cookie_for(donation.user)
      helper.should be_quickdonate_cookie
    end
  end

  describe "#remove_quickdonate_cookie" do
    it "should remove quick_donate_user_id session" do
      cookies.permanent.signed[:quick_donate_user_id] = "some value"
      helper.remove_quickdonate_cookie
      cookies.signed[:quick_donate_user_id].should be_nil
    end
  end

  describe "#remove_action_id_from_session" do
    it "should remove action_id from session" do
      session[:action_id] = "some_donation_id"
      helper.remove_action_id_from_session
      session[:action_id].should be_nil
    end
  end

  describe "#display_quick_donate_enrol?" do
    context "quick donate enabled for donation page and user is on thank you page" do
      before :each do
        @page = create(:page_with_parent)
        previous_page = create(:page, name: "previous page", page_sequence: @page.page_sequence)
        @page.stub(previous: previous_page)
        previous_page.stub(quick_donate_enabled?: true)
      end

      it "should display quick donate enrol section if user not enrolled" do
        helper.stub(enrolled_to_quick_donate?: false)
        helper.display_quick_donate_enrol?(@page).should be true
      end

      it "should not display quick donate enrol section if user already enrolled with a session" do
        helper.stub(enrolled_to_quick_donate?: true)
        helper.stub(just_donated_user: quick_donor)
        cookies.signed[:quick_donate_user_id] = quick_donor.id
        helper.display_quick_donate_enrol?(@page).should be false
      end

      it "should not display quick donate enrol if preceding donation was by paypal" do
        user = create(:user)
        helper.stub(preceding_donation: create(:paypal_donation, user: user))
        helper.display_quick_donate_enrol?(@page).should be false
      end

      it "should display quick donate enrol section if user already enrolled without a session" do
        helper.stub(enrolled_to_quick_donate?: true)
        helper.display_quick_donate_enrol?(@page).should be true
      end

      it "should display quick donate enrol section if user already enrolled with another users quick donate session" do
        helper.stub(enrolled_to_quick_donate?: true)
        session[:quick_donate_user_id] = "another users ID"
        helper.display_quick_donate_enrol?(@page).should be true
      end

      it "should display quick donate enrol section if user not enrolled but has session for another quick donate users" do
        helper.stub(enrolled_to_quick_donate?: false)
        helper.stub(just_donated_user: quick_donor)
        session[:quick_donate_user_id] = "another user ID"
        helper.display_quick_donate_enrol?(@page).should be true
      end
      
      it "should not display quick donate enrol if cc_logged is enabled" do
        Setting.stub(:[]).with(:use_cc_logging).and_return('true')
        helper.display_quick_donate_enrol?(@page).should be false
      end
    end
  end

end
