require File.expand_path(File.dirname(__FILE__) + "../../../spec_helper")
require 'rspec'

describe UpdateNotifier do

  let(:today) { Date.today }
  let(:tomorrow) { Date.tomorrow }
  let(:host) { create(:user)}
  let(:get_together) { create(:get_together, :name => 'Save the kittens!', :from_date => today, :to_date => tomorrow, :from_time => 700, :to_time => 900) }

  before(:each) do
    class MockEmail
      def deliver
        true
      end
    end
    @mock_email = MockEmail.new
  end

  it 'should dispatch an email to attendees when an event changes an important detail' do
    @event = create(:event, :name => "Leo's event", :get_together => get_together, :host => host, :date => today, :capacity => 23, :time => 800)
    @event.confirm!
    @notifier = UpdateNotifier.new(@event)
    @event.update_attributes(:date => tomorrow)
    GetTogetherMailer.should_receive(:event_changed_attendees_notification_email).with(@event).and_return(@mock_email)
    @notifier.notify_attendees_if_important_update
  end

  it 'should not dispatch an email to attendees when important details are unchanged' do
    @event = create(:event, :name => "Leo's event", :get_together => get_together, :host => host, :date => today, :capacity => 23, :time => 800)
    @event.confirm!
    @notifier = UpdateNotifier.new(@event)
    GetTogetherMailer.should_not_receive(:event_changed_attendees_notification_email).with(@event)
    @notifier.notify_attendees_if_important_update
  end

  it 'Should not dispatch update emails to attendees for an unconfirmed event' do
    @event = create(:event, :name => "Leo's event", :get_together => get_together, :host => host, :date => today, :capacity => 23, :time => 800)
    @notifier = UpdateNotifier.new(@event)
    @event.update_attributes(:date => tomorrow)
    GetTogetherMailer.should_not_receive(:event_changed_attendees_notification_email).with(@event)
    @notifier.notify_attendees_if_important_update
  end
end
