require 'spec_helper'

describe Admin::DashboardController do
  before :each do
    sign_in create(:admin_user)
  end

  describe "responding to GET index" do
    describe "pages" do
      before :each do
        @one_day_campaign = create(:campaign)
        @two_day_campaign = create(:campaign)
        @eight_day_campaign = create(:campaign)
        @one_day_page_sequence = create(:page_sequence_with_parent, campaign: @one_day_campaign)
        @two_day_page_sequence = create(:page_sequence_with_parent, campaign: @two_day_campaign)
        @eight_day_page_sequence = create(:page_sequence_with_parent, campaign: @eight_day_campaign)
        @two_day_page = create(:page_with_parent, page_sequence: @two_day_page_sequence, updated_at: 2.days.ago )
        @one_day_page = create(:page_with_parent, page_sequence: @one_day_page_sequence, updated_at: 1.days.ago )
        @eight_day_page = create(:page_with_parent, page_sequence: @eight_day_page_sequence, updated_at: 8.days.ago )
        get :index
      end

      it "should include all pages within the last 7 days," do
        assigns(:pages).should include @one_day_page
        assigns(:pages).should include @two_day_page
        assigns(:pages).should_not include @eight_day_page
      end

      it "should include the associated page sequences and campaigns" do
        assigns(:pages)[0].page_sequence.should == @one_day_page_sequence
        assigns(:pages)[0].page_sequence.campaign.should == @one_day_campaign
      end

      it "should return pages in descending order by updated date" do
        assigns(:pages)[0].should == @one_day_page
        assigns(:pages)[1].should == @two_day_page
      end
    end
  end

end
