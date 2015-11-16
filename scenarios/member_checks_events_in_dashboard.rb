require File.dirname(__FILE__) + "/scenario_helper.rb"

describe "Member checks event details in dashboard", type: :feature, js: true do
  let(:user) { create(:user, email: "mygetup@getup.org.au", first_name: "Bart", last_name: "Simpson", password: "password") }

  context "Events" do
    it "should display details of events the user is hosting or attending" do
      Timecop.travel(Date.new(2013, 7, 1)) do
        attendee = create(:user, first_name: 'Tom', last_name: 'Robinson', email: 'tom@robinson.com', mobile_number: '0434383494', home_number: '02934983')
        hosted_event = create(:event, host: user, date: Date.new(2013, 7, 1), time: 700, name: 'Event I am hosting', address: '1 first st', capacity: 3, attendees: [attendee])
        attending_event = create(:event, date: Date.new(2013, 7, 2), time: 900, name: 'Attending this event', address: '2 second st', capacity: 4, attendees: [user])
        sign_in
        
        click_link 'EVENTS'
        
        event_container = page.find('.content-box')
        hosting_title = event_container.find(:xpath, './div[1]')
        hosting_title.should have_content 'Events you are hosting'
        assert_hosted_event_displays_correctly(event_container.find(:xpath, './div[2]'))
        attending_title = event_container.find(:xpath, './div[3]')
        attending_title.should have_content 'Events you are attending'
        assert_event_being_attended_displays_correctly(event_container.find(:xpath, './div[4]'))
      end
    end

    def assert_hosted_event_displays_correctly(event_box)
      event_box.should have_content 'All for the Kittens!'
      event_box.should have_content '1 first st'
      event_box.should have_content 'Monday, 1 July 2013 7:00 am'
      event_box.should have_content '1 person attending'
      event_box.should have_content '3 person capacity'
      event_box.should have_content 'Tom Robinson'
      event_box.should have_content 'tom@robinson.com'
      event_box.should have_content '0434383494'
      event_box.should have_content '02934983'
    end

    def assert_event_being_attended_displays_correctly(event_box)
      event_box.should have_content 'All for the Kittens!'
      event_box.should have_content '2 second st'
      event_box.should have_content 'Tuesday, 2 July 2013 9:00 am'
      event_box.should have_content '1 person attending'
      event_box.should have_content '4 person capacity'
    end
  end
end
