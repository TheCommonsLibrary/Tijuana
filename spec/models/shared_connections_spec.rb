require 'spec_helper'

describe SharedConnections do
  describe "validation" do
    before :each do
      originator = User.new
      action_taker = User.new
      uae = UserActivityEvent.new
      @shared_connection = SharedConnections.new(originator: originator, action_taker: action_taker, user_activity_event: uae)
    end

    it 'should not save with empty originator' do
      @shared_connection.originator = nil
      @shared_connection.should_not be_valid
    end

    it 'should not save with empty action_taker' do
      @shared_connection.action_taker = nil
      @shared_connection.should_not be_valid
    end

    it 'should not save with empty user_activity_event' do
      @shared_connection.user_activity_event = nil
      @shared_connection.should_not be_valid
    end

    it 'should not save when originator and action_taker are the same' do
      @shared_connection.originator = @shared_connection.action_taker
      @shared_connection.should_not be_valid
    end

    it 'should be a valid object' do
      @shared_connection.should be_valid
    end
  end
end
