require 'spec_helper'
require_relative 'whitelist_filter_shared'

describe DarkFilter::CampaignWhitelistFilter do

  describe "that is recuriting" do
    let!(:email){ create(:email) }
    let(:filter){ create(:active_campaign_whitelist_filter, recruiting: true) }

    describe "#add_member_to_experiment" do
      let!(:member){ create(:user) }


      context "with a user joining from an email" do
        let!(:campaign_for_email){ email.blast.push.campaign }
        before{ filter.add_member_to_experiment(member, email: email) }

        it "should record that the user is in an experiment" do
          DarkFilter::Experiment.where(dark_filter_id: filter.id, control: false, user_id: member.id)
            .count.should == 1
        end

        it "should add a campaign white list entry for the email the user was subscribed on" do
          DarkFilter::CampaignWhiteList.where(user_id: member.id)
            .where(joining_campaign_id: campaign_for_email.id, campaign_id: campaign_for_email.id)
            .count.should == 1 
        end
      end

      context "with a user joining from a page" do
        let!(:page){ create(:page_with_parent) }
        let(:campaign){ page.page_sequence.campaign }
        before{ filter.add_member_to_experiment(member, page: page) }

        it "should add a campaign white list entry for the page the user acted on" do
          DarkFilter::CampaignWhiteList.where(user_id: member.id)
            .where(joining_campaign_id: campaign.id, campaign_id: campaign.id)
            .count.should == 1 
        end
      end

      context "with options whitelist_related_campaigns set to true" do
        let!(:filter){ create(:active_campaign_whitelist_filter, recruiting: true, whitelist_related_campaigns: true) }
        let!(:tags){ ['related', 'ignore', 'another-related'] }
        let!(:related_campaigns){ [ create(:campaign, tag_list: tags.first), create(:campaign, tag_list: tags.last) ] }
        let!(:campaign_for_email){
          campaign = email.blast.push.campaign
          campaign.tag_list = tags
          campaign.save!
          campaign
        }
        before{ filter.add_member_to_experiment(member, email: email) }

        it "should add a campaign white list entry for all campaigns sharing the same tags" do
          related_campaigns.each do |related_campaign|
            DarkFilter::CampaignWhiteList.where(user_id: member.id)
              .where(campaign_id: related_campaign.id)
              .count.should == 1 
          end
        end
      end

      context "re-subscribing member" do
        let!(:member){ create(:user, created_at: 2.days.ago) }
        let!(:page){ create(:page_with_parent) }
        let(:campaign){ page.page_sequence.campaign }
        before{ filter.add_member_to_experiment(member, page: page) }

        it "should NOT add the member to the control" do
          DarkFilter::CampaignWhiteList.where(user_id: member.id)
            .count.should be_zero
        end
      end
    end

    describe "#add_member_to_control" do

      context "with a member that didn't subscribe via a campaign" do
        let!(:member){ create(:user) }
        before{ filter.add_member_to_control(member) }

        it "should NOT add the member to the control or experiment" do
          DarkFilter::Experiment.where(user_id: member.id)
            .count.should be_zero
        end
      end

      context "re-subscribing member" do
        let!(:member){ create(:user, created_at: 2.days.ago) }
        before{ filter.add_member_to_control(member, page: create(:page_with_parent)) }

        it "should NOT add the member to the control" do
          DarkFilter::Experiment.where(user_id: member.id)
            .count.should be_zero
        end
      end
    end
  end

  describe "#filter" do
    let(:filter){ create(:active_campaign_whitelist_filter, recruiting: true) }
    let!(:email){ create(:email) }
    let!(:email_on_campaign){ create(:email) }
    let!(:campaign){ email_on_campaign.blast.push.campaign }
    let!(:non_whitelisted_member){
      member = create(:user)
      filter.add_member_to_experiment(member, email: email)
      member
    }
    let!(:whitelisted_member){
      member = create(:user)
      filter.add_member_to_experiment(member, email: email_on_campaign)
      member
    }
    it_behaves_like "filter with WhitelistFilterConcern"
  end
end
