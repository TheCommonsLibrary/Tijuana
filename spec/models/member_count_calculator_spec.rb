require 'spec_helper'

describe MemberCountCalculator do
  it "should increment the member count by a given factor" do
    MemberCountCalculator.init
    MemberCountCalculator.set_count(10)
    MemberCountCalculator.current.should eql 10

    subscribed = double(:count => 31)
    User.stub(:subscribed) { subscribed }
    MemberCountCalculator.update!.should eql 11
    MemberCountCalculator.current.should eql 11

    subscribed = double(:count => 11 + 25)
    User.stub(:subscribed) { subscribed }
    MemberCountCalculator.update!
    MemberCountCalculator.current.should eql 12

    subscribed = double(:count => 12 + 987)
    User.stub(:subscribed) { subscribed }
    MemberCountCalculator.update!
    MemberCountCalculator.current.should eql 59

    MemberCountCalculator.set_count(677500)
    subscribed = double(:count => 857694)
    User.stub(:subscribed) { subscribed }
    MemberCountCalculator.update!
    MemberCountCalculator.current.should eql 686080
  end

  it "should never go back" do
    MemberCountCalculator.init
    MemberCountCalculator.set_count(10)
    MemberCountCalculator.current.should eql 10
    User.stub_chain(:subscribed, :count) { 0 }

    MemberCountCalculator.update!
    MemberCountCalculator.current.should eql 10
  end

  describe "#init" do
    it "should not reset the counter if it already has a value" do
       User.stub_chain(:subscribed, :count) { 735 }
       MemberCountCalculator.init
       User.stub_chain(:subscribed, :count) { 1000 }
       MemberCountCalculator.init
       MemberCountCalculator.current.should eql 735
     end

    it "should initialize the counter using the real members count as the default value" do
      User.stub_chain(:subscribed, :count) { 735 }
      MemberCountCalculator.init
      MemberCountCalculator.current.should eql 735
    end

    it "should initialize the counter using a given value" do
      MemberCountCalculator.init
      MemberCountCalculator.set_count(666)
      MemberCountCalculator.current.should eql 666
    end
  end
end
