require File.expand_path(File.dirname(__FILE__) + "../../spec_helper")

describe List do
  describe "combine relations" do
    it "should generate sql for multiple rules" do
      list = List.new
      list.set_email_domain_rule(:domain => "@gmail.com")
      list.set_country_rule(:country_iso => "BR")
      list.save

      sql = list.combine_relations.to_sql.gsub(/`/, '').downcase
      sql.should include('from users')
      sql.should include('users.is_member = true')
      sql.should include("users.deleted_at is null")
      sql.should include("email like '%@gmail.com'")
      sql.should include("country_iso = 'br'")
    end

    it "should generate sql for a single rule" do
      list = List.new
      list.set_email_domain_rule(:domain => "@gmail.com")
      list.save

      sql = list.combine_relations.to_sql.gsub(/`/, '').downcase
      sql.should include('from users')
      sql.should include('users.is_member = true')
      sql.should include("users.deleted_at is null")
      sql.should include("email like '%@gmail.com'")
    end

    it "should generate sql to exclude people who have unsubscribed from agra if an agra rule is active" do
      list = List.new
      list.set_agra_role_rule(:role => "creator")
      list.save!
      sql = list.combine_relations.to_sql.gsub(/`/, '').downcase
      sql.should include('from users')
      sql.should include('users.is_member = true')
      sql.should include("users.deleted_at is null")
      sql.should include('users.is_agra_member = true')
      sql.should include('inner join agra_actions')
      sql.should include('on users.id = agra_actions.user_id')
      sql.should include("agra_actions.role = 'creator'")

      list.set_agra_slug_rule(:slug => "agra_action_slug")
      list.save!

      sql = list.combine_relations.to_sql.gsub(/`/, '').downcase
      sql.should include('from users')
      sql.should include('users.is_member = true')
      sql.should include("users.deleted_at is null")
      sql.should include('users.is_agra_member = true')
      sql.should include('inner join agra_actions')
      sql.should include('on agra_actions.user_id = users.id')
      sql.should include("agra_actions.role = 'creator'")
      sql.should include("agra_actions.slug in ('agra_action_slug')")
    end

    it "should generate SQL to include Agra members only, if custom_sql query references agra tables" do
      list = List.new
      list.set_agra_role_rule(:custom_sql => "SELECT u.id FROM users u INNER JOIN agra_actions a ON u.id = a.user_id")
      sql = list.combine_relations.to_sql.gsub(/`/, '').downcase
      sql.should include('users.is_agra_member = true')
    end

    it "should allow its rules to be updated" do
      list = List.new
      list.set_email_domain_rule(:domain => "@gmail.com")
      list.set_country_rule(:country_iso => "BR")
      list.save

      sql = list.combine_relations.to_sql.gsub(/`/, '').downcase
      sql.should include('from users')
      sql.should include('users.is_member = true')
      sql.should include("users.deleted_at is null")
      sql.should include("email like '%@gmail.com'")

      list.set_country_rule(:country_iso => "AU")

      sql = list.combine_relations.to_sql.gsub(/`/, '').downcase
      sql.should include('from users')
      sql.should include('users.is_member = true')
      sql.should include("users.deleted_at is null")
      sql.should include("email like '%@gmail.com'")
      sql.should include("country_iso = 'au'")
    end

    it "should selected subscribed, non-deleted users if no rules specified" do
      list = List.new
      sql = list.combine_relations.to_sql.gsub(/`/, '').downcase
      sql.should include('from users')
      sql.should include('users.is_member = true')
      sql.should include("users.deleted_at is null")
    end
  end

  describe "include_low_volume_members?" do
    it "is true when low volume members are not excluded" do
      list = List.new
      list.should be_include_low_volume_members
    end
    it "is true when low volume members are not excluded" do
      list = List.new
      list.set_exclude_low_volume_members_rule
      list.should_not be_include_low_volume_members
    end
  end

  describe "filter by rules" do
    without_transactional_fixtures do
      it "should filter agra users who have signed agra petitions" do
        agra_signer = create(:user)
        getup_member = create(:user)
        sign_action = create(:agra_action_signer, :user => agra_signer)

        list = List.new
        list.set_agra_role_rule(:role => "signer")
        list.save!
        users = list.filter_by_rules
        users.size.should eql 1
        users[0].should eql agra_signer.id
      end

      it "should filter agra users who have started or taken action on an agra campaign" do
        agra_campaign_user = create(:user)
        getup_member = create(:user)
        sign_action = create(:agra_action_signer, :user => agra_campaign_user)
        list = List.new
        list.set_agra_slug_rule(:slug => "agra-slug")
        list.save!
        users = list.filter_by_rules

        users.size.should eql 1
        users[0].should eql agra_campaign_user.id
      end

      it "should filter agra users from getup users" do
        agra_campaign_user = create(:user)
        getup_member = create(:user)
        sign_action = create(:agra_action_signer, :user => agra_campaign_user)
        list = List.new
        list.set_agra_role_rule(:not => true, :role => 'all')
        list.save!
        users = list.filter_by_rules

        users.size.should eql 1
        users[0].should eql getup_member.id
      end

      it "should return only agra users" do
        agra_campaign_user = create(:user)
        getup_member = create(:user)
        sign_action = create(:agra_action_signer, :user => agra_campaign_user)
        list = List.new
        list.set_agra_role_rule(:role => 'all')
        list.save!
        users = list.filter_by_rules

        users.size.should eql 1
        users[0].should eql agra_campaign_user.id
      end
      
      it "should filter out agra users who have unsubscribed" do
        subscribed_user = create(:user)
        unsubscribed_user = create(:unsubscribed_agra_user)
        create(:agra_action_signer, :user => subscribed_user)
        create(:agra_action_signer, :user => unsubscribed_user)

        list = List.new
        list.set_agra_slug_rule(:slug => "agra-slug")
        list.save!
        users = list.filter_by_rules

        users.size.should eql 1
        users[0].should eql subscribed_user.id

        list = List.new
        list.set_agra_role_rule(:role => "signer")
        list.save!
        users = list.filter_by_rules

        users.size.should eql 1
        users[0].should eql subscribed_user.id
      end

      it "should return users whose email belong to gmail" do
        activity = create(:activity)
        list = List.new
        list.set_email_domain_rule(:domain => "@borges.com")

        users = list.filter_by_rules
        users.size.should == 1
        users[0].should == activity.user.id
      end

      it "should return brazilian users" do
        activity = create(:activity)
        brazilian_activity = create(:brazilian_activity)

        list = List.new
        list.set_country_rule(:country_iso => "BR")

        users = list.filter_by_rules
        users.size.should == 2
        users.should include(activity.user.id, brazilian_activity.user.id)
      end

      it "should return users within 10 km of the postcode 2000" do
        create(:brazilian_activity)
        create(:leo_activity)
        aussie_activity = create(:aussie_activity)

        list = List.new
        list.set_postcode_within_rule(:postcode_ids => [aussie_activity.user.postcode_id], :within => 10)

        users = list.filter_by_rules
        users.size.should == 1
        users[0].should == aussie_activity.user.id
      end

      it "should only return users that have recurring activities if recurring required" do
        donation_one_off_1 = create(:donation, {:frequency => "one_off"})
        donation_one_off_2 = create(:donation, {:frequency => "one_off"})
        donation_weekly_1 = create(:donation, {:frequency => "weekly"})
        donation_weekly_2 = create(:donation, {:frequency => "weekly"})
        donation_monthly_1 = create(:donation, {:frequency => "monthly"})

        list = List.new
        list.set_donor_rule(frequencies: ['one_off'], page_ids: "", active: true)

        users = list.filter_by_rules
        users.size.should == 2
        users.should include(donation_one_off_1.user.id, donation_one_off_2.user.id)

        list.set_donor_rule(frequencies: ['one_off', 'weekly'], page_ids: "", active: true)

        users = list.filter_by_rules
        users.size.should == 4

      end

      it "should only return users that have participated in campaigns" do
        action_taken_activity = create(:action_taken_activity)

        list = List.new
        list.set_campaign_rule(:campaigns => [action_taken_activity.campaign.id])

        users = list.filter_by_rules
        users.size.should == 1
        users[0].should == action_taken_activity.user.id
      end

      it "should return users that took action" do
        action_taken_activity = create(:action_taken_activity)
        create(:subscribed_activity)

        list = List.new
        list.set_action_taken_rule(:page_ids => action_taken_activity.page.id.to_s)
        list.set_country_rule(:country_iso => "AU")

        users = list.filter_by_rules
        users.size.should == 1
        users[0].should == action_taken_activity.user.id
      end

      it "should return users belonging to the specified electorate" do
        create(:aussie_in_edgewater)
        sydney_aussie = create(:aussie)

        list = List.new
        list.set_electorate_rule(:electorate_ids => [sydney_aussie.postcode.electorates[0].id])
        list.set_country_rule(:country_iso => "AU")

        users = list.filter_by_rules
        users.size.should == 1
        users[0].should ==sydney_aussie.id
      end

      it "should return all users if no filter specified" do
        another_aussie = create(:aussie_in_edgewater)
        sydney_aussie = create(:aussie)

        list = List.new
        list.valid?.should be true

        users = list.filter_by_rules
        users.size.should == 2
        users.should include another_aussie.id
        users.should include sydney_aussie.id
      end

      it "should return distinct users based on the user activities" do
        user = create(:leo)
        activity = create(:activity, :user => user, :page_id => 1)
        activity1 = create(:activity, :user => user, :page_id => 1)

        list = List.new
        list.set_action_taken_rule(:page_ids => "1")

        users = list.filter_by_rules
        users.size.should == 1
        users[0].should == activity.user.id
      end
    end
  end

  it "should aggregate individual rules validation errors" do
    list = List.new
    list.set_action_taken_rule
    list.set_email_domain_rule

    list.valid?.should be false
    list.errors[:action_taken_rule].should have(1).error_on(:page_ids)
    list.errors[:email_domain_rule].should have(1).error_on(:domain)
  end

  it "should store query results inside the given list intermediate result" do
    activity = create(:activity)

    list = List.new
    intermediate_result = ListIntermediateResult.create(:list => list)
    list.set_email_domain_rule(:domain => "@borges.com")

    result_id = list.count_stats_and_store_on(intermediate_result)
    expected_results = intermediate_result.data

    list = List.find(list.id)
    list.list_intermediate_results.size.should == 1
    list.list_intermediate_results.first.data.should == expected_results
    list.list_intermediate_results.first.ready.should be true
  end

  it "should return the count for the most recent intermediate result" do
    list = List.create!
    list.list_intermediate_results.create!(:data => {:size => 521})
    list.list_intermediate_results.create!(:data => {:size => 156})

    List.create!.list_intermediate_results.create!(:data => {:size => 999})

    list.latest_user_count.should == 156
  end

  describe 'count_stats_and_store_on' do
    it 'returns error message if error occurs' do
      list = List.new
      intermediate_result = ListIntermediateResult.create(:list => list)
      list.set_email_action_rule(email_id: "-1")
      list.count_stats_and_store_on(intermediate_result)
      intermediate_result.data[:error].should include "Couldn't find Email with 'id'=-1"
    end

    it 'should store query as a select `users.id` from users' do
      list = List.new
      intermediate_result = ListIntermediateResult.create(:list => list)
      list.count_stats_and_store_on(intermediate_result)
      intermediate_result.data[:sql].should include 'SELECT DISTINCT(users.id)'
    end
  end


  describe "excluding specific users" do
    before(:each) do
      @list = List.new
      @list.set_country_rule(:country_iso => "AU")
    end

    without_transactional_fixtures do
      it "should use the modulus function to partition users" do
        user1 = create(:user, :id => 12, :country_iso => 'AU')
        user2 = create(:user, :id => 22, :country_iso => 'AU')
        user = create(:leo)
        email = create_simple_email(:user => user)
        push = email.blast.push

        with_push_table(push) do
          Push.log_activity!(:email_sent, user, email)
          no_jobs = 2

          user_ids = @list.filter_by_rules_excluding_users_from_push(push, {:no_jobs => no_jobs, :current_job_id => 0})
          user_ids.size.should eql 1
          user_ids.first.should eql user2.id

          user_ids = @list.filter_by_rules_excluding_users_from_push(push, {:no_jobs => no_jobs, :current_job_id => 1})
          user_ids.size.should eql 1
          user_ids.first.should eql user1.id
        end
      end
      
      it 'should partition users evenly accross old and new users where new users id started incrementing by 2', :speed => :slow do
        old_users = 1.upto(300).map { |n| create(:user, :id => n, :country_iso => 'AU') }
        new_users = 302.step(500, 2).map { |n| create(:user, :id => n, :country_iso => 'AU') }
        
        user = create(:leo)
        email = create_simple_email(:user => user)
        push = email.blast.push

        with_push_table(push) do
          Push.log_activity!(:email_sent, user, email)
          no_jobs = 2

          user_ids = @list.filter_by_rules_excluding_users_from_push(push, {:no_jobs => no_jobs, :current_job_id => 0})
          new_users.select { |u| user_ids.include?(u.id) }.size.should == 50
          old_users.select { |u| user_ids.include?(u.id) }.size.should == 150

          user_ids = @list.filter_by_rules_excluding_users_from_push(push, {:no_jobs => no_jobs, :current_job_id => 1})
          new_users.select { |u| user_ids.include?(u.id) }.size.should == 50
          old_users.select { |u| user_ids.include?(u.id) }.size.should == 150
        end
      end

      it "should filter out users that have already received an email within the given push" do
        users = ['user1@gmail.com', 'user2@gmail.com', 'user3@gmail.com'].inject([]) do |acc, email|
          acc << create(:user, :email => email, :country_iso => 'AU')
          acc
        end
        email = create_simple_email(:user => users[0])
        push = email.blast.push
        with_push_table(push) do
          Push.log_activity!(:email_sent, users[0], email)
          create(:subscribed_activity, :user => users[1])
          create(:subscribed_activity, :user => users[2])

          user_ids = @list.filter_by_rules_excluding_users_from_push(push)
          user_ids.should be_same_array_regardless_of_order([users[1].id, users[2].id])
        end
      end

      it "should allow a limit to be added to the final query sorting by the user's random column" do
        random = 4
        users = ['user1@gmail.com', 'user2@gmail.com', 'user3@gmail.com', 'user4@gmail.com'].inject([]) do |acc, email|
          user = create(:user, :email => email, :country_iso => 'AU')
          user.random = random
          user.save
          random -= 1
          acc << user
          acc
        end
        email = create_simple_email(:user => users[0])
        push = email.blast.push
        with_push_table(push) do
          Push.log_activity!(:email_sent, users[0], email)

          @list.filter_by_rules_excluding_users_from_push(push).size.should == 3
          result = @list.filter_by_rules_excluding_users_from_push(push, :limit => 2)
          result.size.should == 2
          result.should == [users[3].id, users[2].id]
        end
      end

      it "should not persist the excluded users rule" do
        push = create(:push)
        with_push_table(push) do
          @list.filter_by_rules_excluding_users_from_push(push)
          @list.should have(1).rules
          @list.rules.first.should be_instance_of ListCutter::CountryRule
        end
      end

      context "with a dark filter" do
        let!(:filter){ create(:active_campaign_whitelist_filter) }
        let!(:not_filtered_member){ create(:user, :country_iso => 'AU') }
        let!(:filtered_member){ create(:user, :country_iso => 'AU') }
        let!(:previous_email){ create(:email) }
        let!(:email){ create(:email) }
        let!(:push){ email.blast.push }
        let!(:list){ @list }
        before do
          filter.add_member_to_experiment(filtered_member, email: previous_email)
        end

        context "that is active" do
          it "should exclude filtered members" do
            with_push_table(push) do
              user_ids = list.filter_by_rules_excluding_users_from_push(push)
              user_ids.should be_same_array_regardless_of_order([not_filtered_member.id])
            end
          end
        end

        context "that is not active" do
          before{ filter.active_filter = false; filter.save! }

          it "should not filter members" do
            with_push_table(push) do
              user_ids = list.filter_by_rules_excluding_users_from_push(push)
              user_ids.should be_same_array_regardless_of_order([not_filtered_member.id, filtered_member.id])
            end
          end
        end
      end
    end
  end
end
