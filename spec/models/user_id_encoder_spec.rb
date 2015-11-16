require 'spec_helper'

describe UserIdEncoder do
  before(:each) do
    @user = create(:user)
  end

  describe "#encode" do
    it "should generate valid hash" do
      UserIdEncoder.encode(@user).should_not be_nil
    end

    it "should generate one hash per user" do
      key1 = UserIdEncoder.encode(@user)
      key2 = UserIdEncoder.encode(@user)
      key1.should == key2
    end
  end

  describe "#decode" do
    before(:each) do
      @key = UserIdEncoder.encode(@user)
    end

    def decode(key)
      UserIdEncoder.decode(key)
    end

    it "should decode valid hash" do
      decode(@key).should == @user
    end

    it "should handle nil & empty hashes" do
      decode(nil).should == nil
      decode("").should == nil
    end

    it "should handle missing and malformed hashes" do
      decode("asdfasd3297843fasdf").should == nil
    end

    it "should decode self-encoded hash" do
      user = create(:user)
      decode(UserIdEncoder.encode(user)).should == user
    end
  end
end
