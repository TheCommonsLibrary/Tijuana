require File.expand_path(File.dirname(__FILE__) + "../../spec_helper")

describe EmailStatsTable do
  without_transactional_fixtures do
    it "returns stats for the email" do
      with_push_table do
        push1 = create(:push)
        blast = create(:blast, :push => push1)
        email = create(:email, :blast => blast)
        page = create(:page_with_parent)
        petition = create(:petition_module)
        ContentModuleLink.create!(:page => page, :content_module => petition, :position => 3, :layout_container => :main_content)

        22.times do
          push1.batch_create_sent_activity_event!([create(:user).id], email)
        end
        19.times do
          UserActivityEvent.email_viewed!(create(:user), email)
        end
        15.times do
          UserActivityEvent.email_clicked!(create(:user), email)
        end
        12.times do
          UserActivityEvent.action_taken!(create(:user), page, petition, nil, email)
        end

        stats_table = EmailStatsTable.new(push1.blasts.map(&:emails).flatten).calculate_stats
=begin
        stats_table[email.id][:email_sent][:as_value].should == 22

        {
          :email_viewed => [19, '72% - 100%'],
          :email_clicked => [15, '61% - 97%'],
          :action_taken => [12, '34% - 75%']
        }.each do |metric, values|
          stats_table[email.id][metric][:as_value].should == values[0]
          stats_table[email.id][metric][:as_percentage].should == values[1]
        end
=end
      end
    end

    it "should not go out of boundaries" do
      with_push_table do
        push1 = create(:push)
        blast = create(:blast, :push => push1)
        email = create(:email, :blast => blast)

        15.times do
          push1.batch_create_sent_activity_event!([create(:user).id], email)
        end
        14.times do
          UserActivityEvent.email_viewed!(create(:user), email)
        end
        1.times do
          UserActivityEvent.email_clicked!(create(:user), email)
        end

        stats_table = EmailStatsTable.new(push1.blasts.map(&:emails).flatten).calculate_stats

        stats_table[email.id][:email_viewed][:as_percentage].split[2].to_i.should_not > 100
        stats_table[email.id][:email_clicked][:as_percentage].split[0].to_i.should_not < 0
      end
    end

    it "doesn't throw up with zero values" do
      with_push_table do
        push1 = create(:push)
        blast = create(:blast, :push => push1)
        email = create(:email, :blast => blast)

        15.times do
          push1.batch_create_sent_activity_event!([create(:user).id], email)
        end
        stats_table = EmailStatsTable.new(push1.blasts.map(&:emails).flatten)
        stats_table.calculate_stats[email.id][:email_viewed][:as_value].should == 0
        stats_table.calculate_stats[email.id][:email_viewed][:as_percentage].should == "0%"
      end
    end

    it "should not count the same activity on the same object twice for a given user" do
      with_push_table do
        push1 = create(:push)
        blast = create(:blast, :push => push1)
        email = create(:email, :blast => blast)
        user = create(:user)
        18.times do
          UserActivityEvent.email_viewed!(create(:user), email)
        end
        2.times do
          UserActivityEvent.email_viewed!(user, email)
        end

        stats_table = EmailStatsTable.new(push1.blasts.map(&:emails).flatten)
        stats_table.calculate_stats[email.id][:email_viewed][:as_value].should == 19
      end
    end

    it "should calculate show the number of donations and median" do
      with_push_table do
        push1 = create(:push)
        blast = create(:blast, :push => push1)
        email = create(:email, :blast => blast)
        [100, 400, 100000].each do |amount_in_cents|
          create(:transaction, donation: create(:donation, amount_in_cents: amount_in_cents, email: email))
        end
        stats_table = EmailStatsTable.new(push1.blasts.map(&:emails).flatten)
        column_index = EmailStatsTable.columns.index('Donations')
        expect(stats_table.rows.first[column_index]).to eq(3)
        column_index = EmailStatsTable.columns.index('Median $')
        expect(stats_table.rows.first[column_index]).to eq('$4.00')
      end
    end
  end
end
