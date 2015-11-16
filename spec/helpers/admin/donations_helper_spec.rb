require 'spec_helper'

describe Admin::DonationsHelper do
  describe "#selected_campaign_id" do
    context "donation to ask page" do
      before(:each) do
        @campaign = create(:campaign)
        page_sequence = create(:page_sequence, campaign: @campaign)
        page = create(:page, page_sequence: page_sequence, id: 3) # ensure page_id is not 1
        donation = create(:donation, page: page)
        assign(:donation, donation)
      end

      it "should return campaign the donation belongs to" do
        helper.selected_campaign_id.should == @campaign.id
      end
    end

    context "new donation record" do
      before(:each) do
        assign(:donation, Donation.new)
      end

      it "should return nil" do 
        helper.selected_campaign_id.should be_nil
      end
    end

    context "umbrella donation" do
      before(:each) do
        donation = create(:donation)
        donation.stub(:page_id).and_return(1)
        assign(:donation, donation)
      end

      it "should return nil" do
        helper.selected_campaign_id.should be_nil
      end
    end

    context "donation to static page" do
      before(:each) do
        page_sequence = create(:static_page_sequence)
        page = create(:page, page_sequence: page_sequence)
        donation = create(:donation, page: page)
        assign(:donation, donation)
      end

      it "should return nil" do
        helper.selected_campaign_id.should be_nil
      end
    end
  end
end
