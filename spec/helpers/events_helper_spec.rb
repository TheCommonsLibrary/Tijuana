require File.expand_path(File.dirname(__FILE__) + "../../spec_helper")

describe EventsHelper do
  describe "#can_be_attended?" do
    it "should handle the various states in which users can be in order to attend an event" do
      not_attending_user = create(:user)
      attending_user = create(:user)
      event = create(:event, :date => Date.tomorrow, :confirmed_at => Date.today)
      event.should_receive(:status).at_least(:once).and_return('open')

      event.add_attendee!(attending_user)
      full_event = create(:event, :capacity => 0)
      full_event.should_receive(:status).at_least(:once).and_return('full')

      helper.can_be_attended?(event, event.host).should           be false
      helper.can_be_attended?(event, attending_user).should       be false
      helper.can_be_attended?(event, nil).should                  be true #user not logged in
      helper.can_be_attended?(event, not_attending_user).should   be true

      helper.can_be_attended?(full_event, event.host).should           be false
      helper.can_be_attended?(full_event, attending_user).should       be false
      helper.can_be_attended?(full_event, nil).should                  be false#user not logged in
      helper.can_be_attended?(full_event, not_attending_user).should   be false
    end
  end

  describe "#can_be_changed?" do
    it "should return false for past events or events that have been canceled" do
      event = create(:event, :capacity => 0)
      event.stub(:status) {'canceled'}
      helper.can_be_changed?(event).should be false

      event.stub(:status) {'ended'}
      helper.can_be_changed?(event).should be false

      event.stub(:status) {'anything-else'}
      helper.can_be_changed?(event).should be true

      event.stub(:status) {'open'}
      helper.can_be_changed?(event).should be true
    end
  end

  describe "#should_display_attendees?" do
    it "should return false for past events or events that have been canceled" do
      event = create(:event, :capacity => 0)
      event.stub(:status) {'canceled'}
      helper.should_display_attendees?(event).should be false

      event.stub(:status) {'unconfirmed'}
      helper.should_display_attendees?(event).should be false

      event.stub(:status) {'full'}
      helper.can_be_changed?(event).should be true

      event.stub(:status) {'anything-else'}
      helper.can_be_changed?(event).should be true
    end
    it "should return false for large scale events (>=20)" do
      event = create(:event, :capacity => 20)
      event.stub(:status) {'anything-else'}
      helper.should_display_attendees?(event).should be false
    end
  end

  describe "#sum" do
    it "should return the number of attendees" do
      get_together = create(:get_together)
      5.times do
        event = create(:event, :get_together => get_together, :confirmed_at => Time.now)
        3.times do
          event.add_attendee! create(:user)
        end
      end
      helper.sum(get_together.events, 'attendees').should == 15
    end
  end

  describe "time helper functions" do
    it "should extract the hour and minute components of an event time" do
      event = create(:event, :date => Date.tomorrow, :confirmed_at => Date.today)
      event.time = 800
      helper.event_hour_formatted(event.time).should eql "08"
      helper.event_minute_formatted(event.time).should eql "00"

      event.time = 2035
      helper.event_hour_formatted(event.time).should eql "20"
      helper.event_minute_formatted(event.time).should eql "35"

      event.time = 605
      helper.event_hour_formatted(event.time).should eql "06"
      helper.event_minute_formatted(event.time).should eql "05"

      event.time = 635
      helper.formatted_time(event.time).should eql "06:35"
    end
  end

  describe '#date_within_three_months?' do
    let(:event) { create(:event, :date => Date.tomorrow, :confirmed_at => Date.today) }
    after(:each) { Timecop.return }

    it 'should return true if the current date is up to 3 months after the event' do
      event.date =   Time.local(2013, 6, 1, 10, 0, 0)
      Timecop.freeze(Time.local(2013, 1, 1, 10, 0, 0)) { helper.date_within_three_months?(event.date).should be true }
      Timecop.freeze(Time.local(2013, 5, 1, 10, 0, 0)) { helper.date_within_three_months?(event.date).should be true }
      Timecop.freeze(Time.local(2013, 7, 1, 10, 0, 0)) { helper.date_within_three_months?(event.date).should be true }
      Timecop.freeze(Time.local(2013, 10, 1, 10, 0, 0)) { helper.date_within_three_months?(event.date).should be false }
    end
  end

  def should_include_email_attrs(attrs)
    attrs[:placeholder].should == "Host email address"
    attrs[:class].should == "required email"
  end
end
