require 'spec_helper'

describe DarkFilter::DarkFilter do

  describe "that is recruiting" do
    let(:filter){ create(:generic_filter, recruiting: true) }

    describe "#add_member_to_experiment" do
      let!(:member){ create(:user) }

      before{ filter.add_member_to_experiment(member) }

      it "should record that the user is in an experiment" do
        DarkFilter::Experiment.where(dark_filter_id: filter.id, control: false, user_id: member.id)
          .count.should == 1
      end
    end

    describe "#add_member_to_control" do
      let!(:member_in_control){ create(:user) }
      before{ filter.add_member_to_control(member_in_control) }

      it "should record that the user is in an experiment" do
        DarkFilter::Experiment.where(dark_filter_id: filter.id, control: true, user_id: member_in_control.id)
          .count.should == 1
      end

      context "added again" do

        it "should record that the user is in an experiment" do
          filter.add_member_to_control(member_in_control)
          DarkFilter::Experiment.where(dark_filter_id: filter.id, control: true, user_id: member_in_control.id)
            .count.should == 1
        end
      end
    end
  end

  context "with a recruiting dark filter" do

    let!(:first_filter){ create(:active_campaign_whitelist_filter, created_at: 5.days.ago ) }
    let!(:second_filter){ create(:active_campaign_whitelist_filter, created_at: 4.days.ago) }

    describe ".consider_for_experiment" do
      let(:member){ create(:user) }
      let(:email){ create(:email) }

      context "with an source being community run" do
        let!(:agra_filter){ create(:agra_whitelist_filter, recruiting: true) }
        let!(:category){ 'environment' }
        let!(:campaign_with_matching_category){
          campaign = create(:campaign)
          campaign.tag_list.add(category)
          campaign.save!
          campaign
        }
        before do
          DarkFilter::DarkFilter.consider_for_experiment(member, :source => 'cr', community_run_categories: [category] )
        end

        it "should only use agra filters for agra members" do
          DarkFilter::Experiment.where(user_id: member.id)
            .where(dark_filter_id: agra_filter.id)
            .count.should == 1
        end
      end

      context "with randomness stubbed" do
        before do
          first_sample = nil
          Array.any_instance.stub(:sample){|arg|
            first_sample = !first_sample
            faked_sample_results[first_sample ? 0 : 1]
          }
          DarkFilter::DarkFilter.consider_for_experiment(member, email: email)
        end

        context "sampling groups" do

          context "with random sample returning true for control" do
            let(:faked_sample_results){ [true, first_filter] }
            it "should put the member in the control group" do
              DarkFilter::Experiment.where(control: true, user_id: member.id)
                .count.should == 1
            end
          end

          context "with random sample returning false for control " do
            let(:faked_sample_results){ [false, first_filter] }
            it "should put the member in the control group" do
              DarkFilter::Experiment.where(control: false, user_id: member.id)
                .count.should == 1
            end
          end
        end

        context "spread across dark filters" do
          context "with random sample returning first filter" do
            let(:faked_sample_results){ [true, first_filter] }
            it "should put the member in first filter" do
              DarkFilter::Experiment.where(dark_filter_id: first_filter.id, user_id: member.id)
                .count.should == 1
            end
          end

          context "with random sample returning second filter" do
            let(:faked_sample_results){ [true, second_filter] }
            it "should put the member in first filter" do
              DarkFilter::Experiment.where(dark_filter_id: second_filter.id, user_id: member.id)
                .count.should == 1
            end
          end
        end
      end
    end
  end

  describe "generic filter" do
    let(:filter){ create(:generic_filter) }
    its(:agra_only?){ should be false }
  end
end
