require File.expand_path(File.dirname(__FILE__) + "../../spec_helper")

describe Campaign do
  describe "validations" do
    it "should require a name between 3 and 64 characters" do
      Campaign.new(:name => "Save the kittens!", accounts_key: 'Core').should be_valid
      Campaign.new(:name => "AB", accounts_key: 'Core').should_not be_valid
      Campaign.new(:name => "X" * 64, accounts_key: 'Core').should be_valid
      Campaign.new(:name => "Y" * 65, accounts_key: 'Core').should_not be_valid
    end
  end


  describe "find_or_create_offline_donation_page" do

    it "creates an offline donation placeholder page if it does not exist" do
      campaign = create(:campaign)
      offline_donation_page = campaign.find_or_create_offline_donation_page
      offline_donation_page.name.should == 'Offline Donations'
      offline_donation_page.page_sequence.name.should == 'Offline Donations'
      offline_donation_page.page_sequence.campaign.should == campaign
    end

    it "finds the offline donation placeholder page if it exists" do
      campaign = create(:campaign)
      offline_donation_page = campaign.find_or_create_offline_donation_page
      offline_donation_page.page_sequence.campaign.should == campaign
    end

  end

  describe "#accounts_key" do
    it "should be valiated on create" do
      expect(build(:campaign, accounts_key: nil)).to_not be_valid
    end
  end
end
