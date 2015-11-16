require_relative "../../spec_helper"

describe ListCutter::NoEmailSentTodayRule do
  without_transactional_fixtures do
    before do
      @member1 = create(:user, email: 'member1@example.com')
      @member2 = create(:user, email: 'member2@example.com')
      @member3 = create(:user, email: 'member3@example.com')

      push1 = create(:push, name: 'push1')
      blast1 = create(:blast, push: push1)
      @email1 = create(:email, blast: blast1)

      # don't know why we need to minus 1 second; wtf rails?
      Timecop.freeze(Time.current.yesterday.end_of_day - 1.second) { send_email_to(@member1) }
      Timecop.travel(Time.current.beginning_of_day) { send_email_to(@member2) }
    end

    it "returns all members who haven't received an email since midnight" do
      with_push_table do
        expect(
          subject.to_relation.all.map(&:id)
        ).to eq [@member1, @member3].map(&:id)
      end
    end
  end

  def send_email_to(member)
    create(:sent_email, subject: @email1.subject, body: @email1.body, recipient_count: 1, sql: "SQL", email: @email1)
    Push.log_activity!('email_sent', member, @email1)
  end

end
