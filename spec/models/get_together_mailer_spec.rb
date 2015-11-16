require File.expand_path(File.dirname(__FILE__) + '../../spec_helper')

describe GetTogetherMailer do
  before do
    ActionMailer::Base.deliveries = []
    UserMailer.stub(:welcome_to_getup_email) { double(:deliver=>nil) }
  end

  it 'should send thankyou for hosting email' do
    today = Date.today
    host_notes = "Heavy metal is back!"
    event = create(:event, :name => "Awsome event!", :date => today, :time => 700, :host_notes => host_notes)
    GetTogetherMailer.thankyou_for_hosting_email(event).deliver

    ActionMailer::Base.deliveries.size.should eql(2)
    @delivered = ActionMailer::Base.deliveries.last
    @delivered.parts.length.should be(2)

    html_part = @delivered.parts.select { |part| part.content_type =~ /text\/html/ }.first
    text_part = @delivered.parts.select { |part| part.content_type =~ /text\/plain/ }.first

    text_part.should have_body_text(/http:\/\/localhost\/events\/confirm\?cd=#{event.confirmation_code}/)
    html_part.should have_body_text(/http:\/\/localhost\/events\/confirm\?cd=#{event.confirmation_code}/)

    @delivered.should have_subject(/your GetUp! Event/)
    @delivered.should deliver_to(event.host.email)
  end

  it 'should send thankyou for attending email' do
    today = Date.today
    host_notes = "Heavy metal is back!"
    attendee = create(:user, :first_name => "Ozzy", :email => "ozzy@osbourne.com")
    event = create(:event, :name => "Awsome event!", :date => today, :time => 700, :host_notes => host_notes)
    GetTogetherMailer.thankyou_for_attending_email(event, attendee).deliver

    ActionMailer::Base.deliveries.size.should eql(2)
    @delivered = ActionMailer::Base.deliveries.last
    @delivered.parts.length.should be(2)

    assert_contents_present(@delivered.parts[0], event, host_notes, today, /http:\/\/localhost\/events\/all-for-the-kittens-awsome-event/)
    assert_contents_present(@delivered.parts[1], event, host_notes, today, /<a href="http:\/\/localhost\/events\/all-for-the-kittens-awsome-event">http:\/\/localhost\/events\/all-for-the-kittens-awsome-event<\/a>/)

    @delivered.should have_subject(/Thanks for RSVPing to the "#{event.name}" event/)
    @delivered.should deliver_to(attendee.email)
  end

  it "should send an email to a event's host when a user RSVPs to it" do
    today = Date.today
    host_notes = "Heavy metal is back!"
    attendee = create(:user, :first_name => "Ozzy", :email => "ozzy@osbourne.com")
    event = create(:event, :name => "Awsome event!", :date => today, :time => 700, :host_notes => host_notes)

    GetTogetherMailer.someone_is_attending_your_event_email(event, attendee).deliver

    ActionMailer::Base.deliveries.size.should eql(2)
    @delivered = ActionMailer::Base.deliveries.last
    @delivered.parts.length.should be(2)

    @delivered.parts.each do |part|
      part.should have_body_text(/#{event.name}/)
      part.should have_body_text(/http:\/\/localhost\/events\/all-for-the-kittens-awsome-event/)
    end

    @delivered.should have_subject(/A GetUp! member just registered to your "#{event.name}" event/)
    @delivered.should deliver_to(event.host.email)
  end

  it "should notify the host that a user canceled his attendance" do
    today = Date.today
    host_notes = "Heavy metal is back!"
    attendee = create(:user, :first_name => "Ozzy", :email => "ozzy@osbourne.com")
    event = create(:event, :name => "Awsome event!", :date => today, :time => 700, :host_notes => host_notes)

    GetTogetherMailer.someone_canceled_their_attendance_email(event, attendee, "can't come").deliver

    ActionMailer::Base.deliveries.size.should eql(2)
    @delivered = ActionMailer::Base.deliveries.last
    @delivered.parts.length.should be(2)

    @delivered.should have_subject(/A GetUp! member has just cancelled attendance to your event \"#{event.name}\"./)
    @delivered.should deliver_to(event.host.email)
  end

  it "should send attendance canceled confirmation to the attendee" do
    today = Date.today
    host_notes = "Heavy metal is back!"
    attendee = create(:user, :first_name => "Ozzy", :email => "ozzy@osbourne.com")
    event = create(:event, :name => "Awsome event!", :date => today, :time => 700, :host_notes => host_notes)

    GetTogetherMailer.attendance_canceled_confirmation_email(event, attendee).deliver

    ActionMailer::Base.deliveries.size.should eql(2)
    @delivered = ActionMailer::Base.deliveries.last
    @delivered.parts.length.should be(2)

    @delivered.should have_subject(/Your attendance of the \"#{event.name}\" event has been cancelled./)
    @delivered.should deliver_to(attendee.email)
  end

  it "should send the event canceled confirmation email to the event's host" do
    event = create(:event)

    GetTogetherMailer.event_canceled_confirmation_email(event).deliver

    ActionMailer::Base.deliveries.size.should eql(2)
    @delivered = ActionMailer::Base.deliveries.last
    @delivered.parts.length.should be(2)

    @delivered.should have_subject(/Your event has been cancelled!/)
    @delivered.should deliver_to(event.host.email)
  end

  context "event has attendees" do
    it "should send email to all attendees" do
      today = Date.today
      attendee = create(:user, :first_name => "Ozzy", :email => "ozzy@osbourne.com")
      attendee1 = create(:user, :first_name => "Ozzy", :email => "dude@osbourne.com")
      event = create(:event, :name => "Awsome event!", :date => today, :time => 700, :attendees => [attendee, attendee1])
      msg = "The message"

      GetTogetherMailer.message_attendees_email(event, msg).deliver

      ActionMailer::Base.deliveries.size.should eql(2)
      @delivered = ActionMailer::Base.deliveries.last

      @delivered.should have_body_text(/#{msg}/)

      @delivered.should have_subject(/The host of your GetUp! \"#{event.name}\" event has sent you a message./)
      @delivered.header['X-SMTPAPI'].value.should match(/ozzy@osbourne.com/)
      @delivered.header['X-SMTPAPI'].value.should match(/dude@osbourne.com/)
      @delivered.should deliver_from(event.host.email)
    end

    it "should send the canceled event notification email out to attendees" do
      attendees = [create(:user, :email => "party@guy.com"), create(:user, :email => "party@guy2.com")]
      event = create(:event, :attendees => attendees)

      GetTogetherMailer.event_canceled_attendees_notification_email(event).deliver

      ActionMailer::Base.deliveries.size.should eql(2)
      @delivered = ActionMailer::Base.deliveries.last
      @delivered.parts.length.should be(2)

      @delivered.should have_subject(/The event you have RSVP'd to has been cancelled!/)
      @delivered.should bcc_to(attendees.map(&:email))
    end

    it "should send the details changed event notification email out to attendees" do
      attendees = [create(:user, :email => "party@guy3.com"), create(:user, :email => "party@guy4.com")]
      event = create(:event, :attendees => attendees)

      GetTogetherMailer.event_changed_attendees_notification_email(event).deliver

      ActionMailer::Base.deliveries.size.should eql(2)
      @delivered = ActionMailer::Base.deliveries.last
      @delivered.parts.length.should be(2)

      @delivered.should have_subject(/The GetUp! event you RSVP'd to has been changed/)
      @delivered.should bcc_to(attendees.map(&:email))
    end
  end


  context "event has no attendees" do
    it "should not attempt to send email" do
      today = Date.today
      event = create(:event, :name => "Awsome event!", :date => today, :time => 700, :attendees => [])
      msg = "The message"
      GetTogetherMailer.message_attendees_email(event, msg).deliver
      ActionMailer::Base.deliveries.size.should eql(1) # This is the event creation email to the host
    end

    it "should not attempt to send the canceled event notification email" do
      event = create(:event, :attendees => [])
      GetTogetherMailer.event_canceled_attendees_notification_email(event).deliver
      ActionMailer::Base.deliveries.size.should eql(1) # This is the event creation email to the host
    end

    it "should not send the details changed event notification email" do
      event = create(:event, :attendees => [])
      GetTogetherMailer.event_changed_attendees_notification_email(event).deliver
      ActionMailer::Base.deliveries.size.should eql(1) # This is the event creation email to the host
    end
  end
end

def assert_contents_present(part, event, host_notes, today, event_url_regex)
  part.should have_body_text(/07:00/)
  part.should have_body_text(/#{host_notes}/)
  part.should have_body_text(/#{event.name}/)
  part.should have_body_text(/#{I18n.localize(today)}/)
  part.should have_body_text(event_url_regex)
end
