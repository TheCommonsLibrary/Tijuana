require 'spec_helper'

shared_examples "filter with WhitelistFilterConcern" do

  # assumes :filter, :email, :whitelisted_member, :non_whitelisted_member and
  # :campaign are defined

  context "with a user that is not in the experiment" do
    let!(:member_not_in_experiment){ create(:user) }
    it "they should pass the filter" do
      filter.filter(campaign).should be_include(member_not_in_experiment)
    end
  end

  context "with a user that is NOT whitelisted for the campaign" do
    it "they should be filtered" do
      filter.filter(campaign).should_not be_include(non_whitelisted_member)
    end
  end

  context "with a user that is whitelisted for the campaign" do
    it "they should pass the filter" do
      filter.filter(campaign).should be_include(whitelisted_member)
    end
  end
end
