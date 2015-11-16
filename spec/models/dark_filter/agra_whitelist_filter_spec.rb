require 'spec_helper'
require_relative 'whitelist_filter_shared'

describe DarkFilter::AgraWhitelistFilter do

  describe "that is recuriting" do
    let!(:member){ create(:user) }
    let(:filter){ create(:agra_whitelist_filter, recruiting: true) }

    describe "#add_member_to_experiment" do
      context "with a member that doesn't have any community run categories set in subscription_data" do
        before{ filter.add_member_to_experiment(member) }

        it "should NOT add the member to the experiment" do
          DarkFilter::Experiment.where(user_id: member.id)
            .count.should be_zero
        end
      end

      context "with campaigns that have tags that match the agra subscription data" do
        let!(:matching_campaign){
          campaign = create(:campaign)
          campaign.tag_list.add('economic_justice')
          campaign.save!
          campaign
        }
        before{ filter.add_member_to_experiment(member, { community_run_categories: ['environment', 'economic_justice'] }) }

        context "with a campaign with a tag matching a community run category" do
          it "should add the member to the experiment" do
            DarkFilter::Experiment.where(user_id: member.id)
              .where(dark_filter_id: filter.id)
              .where(control: false)
              .count.should == 1
          end

          it "should add a campaign white list entry for the matching campaign" do
            DarkFilter::CampaignWhiteList.where(user_id: member.id)
              .where(dark_filter_id: filter.id)
              .where(campaign_id: matching_campaign.id)
              .count.should == 1 
          end
        end
      end
    end

    describe "#add_member_to_control" do
      context "with a member that doesn't have any community run categories set in subscription_data" do
        let!(:member){ create(:user) }
        before{ filter.add_member_to_control(member) }

        it "should NOT add the member to the control" do
          DarkFilter::Experiment.where(user_id: member.id)
            .count.should be_zero
        end
      end
    end
  end

  describe "#filter" do
    let(:filter){ create(:agra_whitelist_filter, recruiting: true) }
    let!(:email){ create(:email) }
    let!(:cr_category){ 'test' }
    let!(:another_cr_category){ 'test2' }
    let!(:campaign){
      campaign = create(:campaign)
      campaign.tag_list.add(cr_category)
      campaign.save!
      campaign
    }
    let!(:another_campaign){
      campaign = create(:campaign)
      campaign.tag_list.add(another_cr_category)
      campaign.save!
      campaign
    }
    let!(:non_whitelisted_member){
      member = create(:user)
      filter.add_member_to_experiment(member, { community_run_categories: [another_cr_category] })
      member
    }
    let!(:whitelisted_member){
      member = create(:user)
      filter.add_member_to_experiment(member, { community_run_categories: [cr_category] })
      member
    }
    it_behaves_like "filter with WhitelistFilterConcern"
  end
end
