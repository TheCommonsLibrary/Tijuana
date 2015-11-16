require File.expand_path(File.dirname(__FILE__) + "../../spec_helper")

describe Event do
  let(:today) { Date.today }
  let(:tomorrow) { Date.tomorrow }
  let(:host) { create(:user)}
  let(:get_together) { create(:get_together, :name => "Save the kittens!", :from_date => today, :to_date => tomorrow, :from_time => 700, :to_time => 900) }
  let(:no_time_get_together) { create(:get_together, :name => "Save the kittens!", :from_date => today, :to_date => tomorrow, :from_time => nil, :to_time => nil) }
  let(:event) { create(:event, :name => "Leo's event", :get_together => get_together, :host => host, :date => today, :time => 700) }

  it "should have a long name including its GetTogether's name" do
    event.long_name.should eql "Save the kittens! Leo's event"
  end

  it "should use its long name as the source for its friendly id" do
    event.friendly_id.should eql "save-the-kittens-leo-s-event"
  end

  it "should return whether a user is the host" do
    event.has_host?(host).should == true
  end

  describe "Validation" do
    it "should validate all required fields" do
      e = Event.new
      e.get_together = create(:get_together, :from_date => today, :to_date => tomorrow)
      e.valid?.should be false
      e.errors[:name].size.should > 0
      e.errors[:address].size.should > 0
      e.errors[:date].size.should > 0
      e.errors[:time].size.should > 0
    end

    it "should have date within its GetTogether limits" do
      event.date = Date.today
      event.valid?.should be true
      event.date = 2.days.from_now
      event.valid?.should be false
      event.errors[:date].size.should > 0
    end

    it "should have time within its GetTogether limits" do
      event.time = 700
      event.valid?.should be true
      event.time = 1000
      event.valid?.should be false
      event.errors[:time].size.should > 0
    end

    it "should not validate time if its GetTogether has no time restrictions" do
      event.get_together = no_time_get_together
      event.time = 0
      event.valid?.should be true
    end
  end

  describe "Confirmation" do
    context "Admin managed" do
      before(:each) do
        get_together.is_admin_managed = true
      end

      it 'should not send confirmation ask email' do
        GetTogetherMailer.should_not_receive(:thankyou_for_hosting_email)
        create(:event, name: "Leo's event", get_together: get_together, host: host, date: today, time: 700, confirmed_at: Time.now)
      end

      it "should send a confirmation done email" do
        GetTogetherMailer.should_receive(:event_created_and_public_confirmation_email).and_return(double(:deliver=>true))
        create(:event, name: "Leo's event", get_together: get_together, host: host, date: today, time: 700, confirmed_at: Time.now)
      end

      it "should not generate confirmation_code" do
        Event.should_not_receive(:generate_confirmation_code)
        create(:event, name: "Leo's event", get_together: get_together, host: host, date: today, time: 700, confirmed_at: Time.now)      end
    end

    context "User managed" do
      it "should not be confirmed after creation" do
        event.confirmed_at.should be_nil
        event.confirmed?.should be false
      end

      it 'should send confirmation ask email for user event' do
        GetTogetherMailer.should_receive(:thankyou_for_hosting_email).and_return(double(:deliver=>true))
        create(:event, :name => "Leo's event", :get_together => get_together, :host => host, :date => today, :time => 700)
      end

      it "should not send a confirmation done email" do
        GetTogetherMailer.should_not_receive(:event_created_and_public_confirmation_email)
        create(:event, :name => "Leo's event", :get_together => get_together, :host => host, :date => today, :time => 700)
      end

      it "should confirm the event by verifying the given confirmation code" do
        cd = Digest::SHA1.hexdigest([event.host.email, event.created_at.to_i, event.id].join("--"))
        e = Event.find_by_confirmation_code(cd)
        e.confirm!
        e.confirmed_at.should_not be_nil
        e.confirmed?.should be true
        e.confirmation_code.should be_nil
      end

      it "should not confirm the event if given confirmation code doesn't match any events" do
        cd = Digest::SHA1.hexdigest("whatever")
        e = Event.find_by_confirmation_code(cd)
        e.should be_nil

        event.confirmed_at.should be_nil
        event.confirmed?.should be false
      end
    end
  end

  describe "updating event" do
    it "should not allow the capacity to be made smaller than the number of attendees" do
      original_capacity = 10
      event.update_attributes(:capacity => original_capacity)
      event.stub_chain(:attendees, :size).and_return(4)
      event.update_attributes(:capacity => 1)
      Event.find_by_id(event.id).capacity.should == original_capacity
    end
  end

  describe "#cancel" do
    it "should notify both the host and the attendees" do
      event.update_attribute(:capacity, 1)
      event.attendees << host
      event.save!
      event.canceled?.should be false
      event.canceled_at.should be_nil
      GetTogetherMailer.should_receive(:event_canceled_confirmation_email).with(event).and_return(double(:deliver=>true))
      GetTogetherMailer.should_receive(:event_canceled_attendees_notification_email).with(event).and_return(double(:deliver=>true))

      event.cancel!

      event.canceled?.should be true
      event.canceled_at.should_not be_nil      
    end
  end

  describe "#attend" do
    before(:each) do
      @user = create(:user)
    end
    it "should add the user to the attendees list" do
      GetTogetherMailer.should_receive(:thankyou_for_attending_email).with(event, @user).and_return(double(:deliver=>true))
      GetTogetherMailer.should_receive(:someone_is_attending_your_event_email).with(event, @user).and_return(double(:deliver=>true))

      event.add_attendee!(@user).should be true

      event.attendees.should include @user
    end

    it "should not add attendee if event is full" do
      event.update_attribute(:capacity, 0)

      event.add_attendee!(@user).should be false

      event.attendees.should_not include @user
    end

    it "should raise an error if the user is already attending the event" do
      event.add_attendee!(@user)
      expect { event.add_attendee!(@user) }.to raise_exception(UserAlreadyAttendingError)
    end

    it "should raise an error if the host attempts to attend again" do
      expect { event.add_attendee!(event.host) }.to raise_exception(UserAlreadyAttendingError)
    end
    
  end

  describe "#cancel_attendance" do
    let(:user) { create(:user) }

    before(:each) do
      event.add_attendee!(user)
    end

    it "should remove the user from the list of attendees and notify the host & attendee" do
      reason = "can't come."
      GetTogetherMailer.should_receive(:someone_canceled_their_attendance_email).with(event, user, reason).and_return(double(:deliver=>true))
      GetTogetherMailer.should_receive(:attendance_canceled_confirmation_email).with(event, user).and_return(double(:deliver=>true))
      event.attendees.should include user

      event.cancel_attendance!(user, reason).should be true
      event.reload
      
      event.attendees.should_not include user
    end

    it "should do nothing if the user is not attending the event" do
      another_user = create(:user)
      event.attendees.should_not include another_user

      event.cancel_attendance!(another_user, nil).should be false

      event.attendees.should_not include another_user
    end
  end

  describe "Status" do
    it "should return a status of unconfirmed" do
      event.status.should == 'unconfirmed'
    end

    it "should return a status of open" do
      event.update_attributes(:capacity => 10, :confirmation_code => "1234")
      event = Event.find_by_confirmation_code("1234")
      event.confirm!
      # event = Event.confirm!("1234")
      event.confirmed?.should == true
      event.status.should == 'open'
    end

    it "should return a status of full" do
      event.update_attributes(:capacity => 10, :confirmation_code => "1234")
      event = Event.find_by_confirmation_code("1234")
      event.confirm!
      # event = Event.confirm!("1234")
      event.should_receive(:is_full?).and_return(true)

      event.status.should == 'full'
    end

    it "should return if an event is empty" do
      event.update_attributes(:capacity => 10, :confirmation_code => "1234")
      event = Event.find_by_confirmation_code("1234")
      event.confirm!
      # event = Event.confirm!("1234")
      event.is_empty?.should be true

      attending = create(:user)
      event.add_attendee!(attending)
      event.is_empty?.should be false
    end

    it "should return a status code of ended" do
      event.update_attributes(:confirmation_code => "1234")
      event = Event.find_by_confirmation_code("1234")
      event.confirm!
      # event = Event.confirm!("1234")
      event.update_attributes(:date => Date.yesterday)

      event.status.should == 'ended'
    end
  end

  describe "#has_attendee?" do
    it "should do its thing" do
      attending = create(:user)
      not_attending = create(:user)
      event.add_attendee!(attending)

      event.has_attendee?(attending).should be true
      event.has_attendee?(not_attending).should be false
    end
  end

  describe "#message_attendees" do
    it "should deliver the message to all attendees" do
      attending = create(:user)
      event.add_attendee!(attending)
      msg = "It's a trap"
      GetTogetherMailer.should_receive(:message_attendees_email).with(event, msg).and_return(double(:deliver=>true))

      event.message_attendees(msg).should be true
    end

    it "should not deliver emails if no message is given" do
      attending = create(:user)
      event.add_attendee!(attending)
      GetTogetherMailer.should_not_receive(:message_attendees_email).with(event, "")

      event.message_attendees("").should be false
    end

    it "should not deliver emails if there are no attendees" do
      event.attendees.size.should eql 0
      GetTogetherMailer.should_not_receive(:message_attendees_email).with(event, "fsdfs")

      event.message_attendees("fsdfs").should be false
    end
  end

  describe "number_of_attendees" do

    it "returns number_of_attendees when not available from query" do
      event.add_attendee!(create(:user))
      event.number_of_attendees.should == 1
    end

    it "returns number_of_attendees when available from query" do
      event.add_attendee!(create(:user))

      event_with_number = Event.where(id: event.id).with_number_of_attendees.first
      event_with_number.number_of_attendees.should == 1
    end
  end

  describe 'with_number_of_attendees' do
    it 'makes number_of_attendees available attribute on model' do
      event.add_attendee!(create(:user))
      event_with_number = Event.where(id: event.id).with_number_of_attendees.first
      event_with_number.read_attribute(:number_of_attendees).should == 1
    end
  end

  describe 'capacity_remaining' do
    it "should be the difference between capacity and number of attendees" do
      event.capacity = 10
      event.add_attendee!(create(:user))
      event.capacity_remaining.should == 9
    end
  end
end
