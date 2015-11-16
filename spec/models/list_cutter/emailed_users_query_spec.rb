require "spec_helper"

describe ListCutter::EmailedUsersQuery do
  without_transactional_fixtures do
    before do
      setup_member_emails
      Timecop.travel(Time.local(2014,10,27,9,30))
      # so, in the last 3 days:
      #   @member1 has received 3 emails
      #   @member2 has received 1 email
      #   @member3 hasn't been emailed at all
    end

    context "within the last 3 days" do
      let(:emailed_users_query) { ListCutter::EmailedUsersQuery.new(since: 3.days.ago) }

      describe "#emailed_n_times" do
        it "retrieves all members who haven't been emailed" do
          with_push_table do
            expect(
              emailed_users_query.emailed_n_times(0).all.map(&:id)
            ).to eq([@member3.id])
          end
        end

        it "retrieves all members who have been emailed 1 times or fewer" do
          with_push_table do
            expect(
              emailed_users_query.emailed_n_times(1).all.map(&:id)
            ).to eq [@member2, @member3].map(&:id)
          end
        end

        it "retrieves all members who have been emailed 3 times or fewer" do
          with_push_table do
            expect(
              emailed_users_query.emailed_n_times(3).all.map(&:id)
            ).to eq [@member1, @member2, @member3].map(&:id)
          end
        end

      end
    end

    context "with multiple blasts & pushes" do
      let(:emailed_users_query) { ListCutter::EmailedUsersQuery.new(since: 3.days.ago).emailed_n_times(3) }

      it "does not include duplicate sub-queries" do
        with_push_table do
          blast2 = create(:blast, push: @push1)
          email2 = create(:email, blast: blast2)
          sent_email2 = create(:sent_email, subject: email2.subject, body: email2.body, recipient_count: 3, sql: "SQL", email: email2)

          expect(emailed_users_query.to_sql.scan("push_#{@push1.id}").size).to eq(1)
        end
      end

      it "unions push tables properly" do
        with_push_table do
          send_email_to(create(:email), create(:user))

          expect(emailed_users_query.to_sql.scan("push_").size).to eq(2)
          expect(emailed_users_query.to_sql.scan("union").size).to eq(1)
        end
      end
    end

    context "with multiple rules used together" do
      let(:query1) { ListCutter::EmailedUsersQuery.new(since: 3.days.ago).emailed_n_times(3) }
      let(:query2) { ListCutter::EmailedUsersQuery.new(since: 1.days.ago).emailed_n_times(0) }

      it "should apply the rules correctly" do
        query1.merge(query2).all.should == [@member3]
      end
    end
  end

  def setup_member_emails
    Timecop.travel(Time.local(2014,10,25,9,30)) {
      @push1 = create(:push, name: "push1")
      @blast1 = create(:blast, push: @push1)
      @email1 = create(:email, blast: @blast1)
      @member1 = create(:user)
      @member2 = create(:user)
      @member3 = create(:user)
      send_email_to(@email1, @member1)
    }

    Timecop.travel(Time.local(2014,10,26,9,30)) {
      send_email_to(@email1, @member1)
      send_email_to(@email1, @member2)
    }

    Timecop.travel(Time.local(2014,10,27,9,30)) {
      send_email_to(@email1, @member1)
    }
  end

  def send_email_to(email, member)
    create(:sent_email, subject: email.subject, body: email.body, recipient_count: 1, sql: "SQL", email: email)
    Push.log_activity!('email_sent', member, email)
  end
end
