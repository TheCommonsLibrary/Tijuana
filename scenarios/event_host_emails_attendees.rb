require File.dirname(__FILE__) + "/scenario_helper.rb"

describe "Member emails attendees of event they are hosting", type: :feature, js: true, :driver => :webkit do

  context "logged in" do

    before(:each) do
      Delayed::Worker.delay_jobs = false
      Timecop.travel(Date.new(2013, 7, 1))
      host = create(:user, email: "mygetup@getup.org.au", first_name: "Bart", last_name: "Simpson", password: "password")
      attendee = create(:user, first_name: 'Tom', last_name: 'Robinson', email: 'tom@robinson.com', mobile_number: '0434383494', home_number: '02934983')
      get_together = create(:get_together, is_admin_managed: true)
      @event = create(:event, host: host, get_together: get_together, date: Date.new(2013, 7, 1), time: 700, name: 'Event I am hosting', address: '1 first st', capacity: 3, confirmed_at: Time.now, attendees: [attendee])
      ActionMailer::Base.deliveries = []
      sign_in
    end

    after(:each) do
      Timecop.return
      Delayed::Worker.delay_jobs = true
    end

    it "should send email to attendees" do
      visit event_path(@event)
      fill_in 'message', with: 'this is your host talking to you.'
      click_button 'Send Message'
      page.should have_content('Your message is in the process of being sent')
      email = ActionMailer::Base.deliveries.last
      email.header.to_s.should include('tom@robinson.com')
      email.should have_body_text(/this is your host talking to you/)
    end
  end
end
