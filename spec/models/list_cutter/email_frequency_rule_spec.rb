require File.expand_path(File.dirname(__FILE__) + "../../../spec_helper")

describe ListCutter::EmailFrequencyRule do
  context 'rule' do
    without_transactional_fixtures do
      context 'not negated' do

        it 'should return all users if no emails have been sent in the time period' do
          with_push_table do
            user1 = create(:user, email:"user1@email.com")
            user2 = create(:user, email:"user2@email.com")
            rule = ListCutter::EmailFrequencyRule.new(email_frequency: '5', time_period: '3')
            user_ids = rule.to_relation.all.map(&:id)
            user_ids.uniq.size.should == 2
            user_ids.should include(user1.id, user2.id)
          end
        end

        it 'should return users who have received less emails than specified within the time period' do
          with_push_table do
            Timecop.freeze {
              user1 = create(:user, email:"user1@email.com")
              user2 = create(:user, email:"user2@email.com")
              user3 = create(:user, email:"user3@email.com")
              user4 = create(:user, email:"user4@email.com")
              user5 = create(:user, email:"user5@email.com") # should be included as we want users that have ALSO never received an email in the defined time frame

              push1 = create(:push, created_at: 1.day.ago, name: 'push1')
              push2 = create(:push, created_at: 3.days.ago, name: 'push2')
              push3 = create(:push, created_at: 7.days.ago, name: 'push3')
              push4 = create(:push, created_at: 10.days.ago, name: 'push4')

              blast1 = create(:blast, push: push1, created_at: 1.day.ago)
              blast2 = create(:blast, push: push2, created_at: 3.days.ago)
              blast3 = create(:blast, push: push3, created_at: 7.days.ago)
              blast4 = create(:blast, push: push4, created_at: 10.days.ago)

              email1 = create(:email, blast: blast1, created_at: 1.day.ago)
              email2 = create(:email, blast: blast2, created_at: 3.days.ago)
              email3 = create(:email, blast: blast3, created_at: 7.days.ago)
              email4 = create(:email, blast: blast4, created_at: 10.days.ago)

              sent_email1 = create(:sent_email, subject: email1.subject, body: email1.body, recipient_count: 3, sql: "SQL", email: email1, created_at: 1.day.ago)
              sent_email2 = create(:sent_email, subject: email2.subject, body: email2.body, recipient_count: 3, sql: "SQL",email: email2, created_at: 2.days.ago)
              sent_email3 = create(:sent_email, subject: email3.subject, body: email3.body, recipient_count: 1, sql: "SQL",email: email3, created_at: 7.days.ago)
              sent_email4 = create(:sent_email, subject: email4.subject, body: email4.body, recipient_count: 2, sql: "SQL",email: email4, created_at: 10.days.ago)

              push1.batch_create_sent_activity_event!([user1.id, user2.id, user3.id], email1)
              push2.batch_create_sent_activity_event!([user2.id, user3.id, user4.id], email2)
              push3.batch_create_sent_activity_event!([user3.id], email3)
              push4.batch_create_sent_activity_event!([user3.id, user4.id], email4)

              rule = ListCutter::EmailFrequencyRule.new(email_frequency: '1', time_period: '3')
              user_ids = rule.to_relation.all.map(&:id)
              user_ids.uniq.size.should == 3
              user_ids.should include(user1.id, user4.id, user5.id)
            }
          end
        end

        context 'with email frequency set to 0' do
          it 'should return users who have received no emails within the specified time period' do
            with_push_table do
              Timecop.freeze {
                user1 = create(:user, email:"user1@email.com")
                user2 = create(:user, email:"user2@email.com")
                user3 = create(:user, email:"user3@email.com")
                user4 = create(:user, email:"user4@email.com")

                push1 = create(:push, created_at: 1.day.ago, name: 'push1')
                push2 = create(:push, created_at: 3.days.ago, name: 'push2')
                push3 = create(:push, created_at: 7.days.ago, name: 'push3')
                push4 = create(:push, created_at: 10.days.ago, name: 'push4')

                blast1 = create(:blast, push: push1, created_at: 1.day.ago)
                blast2 = create(:blast, push: push2, created_at: 3.days.ago)
                blast3 = create(:blast, push: push3, created_at: 7.days.ago)
                blast4 = create(:blast, push: push4, created_at: 10.days.ago)

                email1 = create(:email, blast: blast1, created_at: 1.day.ago)
                email2 = create(:email, blast: blast2, created_at: 3.days.ago)
                email3 = create(:email, blast: blast3, created_at: 7.days.ago)
                email4 = create(:email, blast: blast4, created_at: 10.days.ago)

                sent_email1 = create(:sent_email, subject: email1.subject, body: email1.body, recipient_count: 3, sql: "SQL", email: email1, created_at: 1.day.ago)
                sent_email2 = create(:sent_email, subject: email2.subject, body: email2.body, recipient_count: 3, sql: "SQL",email: email2, created_at: 3.days.ago)
                sent_email3 = create(:sent_email, subject: email3.subject, body: email3.body, recipient_count: 1, sql: "SQL",email: email3, created_at: 7.days.ago)
                sent_email4 = create(:sent_email, subject: email4.subject, body: email4.body, recipient_count: 2, sql: "SQL",email: email4, created_at: 10.days.ago)

                push1.batch_create_sent_activity_event!([user1.id, user2.id, user3.id], email1)
                push2.batch_create_sent_activity_event!([user2.id, user3.id, user4.id], email2)
                push3.batch_create_sent_activity_event!([user3.id], email3)
                push4.batch_create_sent_activity_event!([user3.id, user4.id], email4)

                rule = ListCutter::EmailFrequencyRule.new(email_frequency: '0', time_period: '2')
                user_ids = rule.to_relation.all.map(&:id)
                user_ids.uniq.size.should == 1
                user_ids.should include(user4.id)
              }
            end
          end
        end

      end
    end
  end
end
