require File.expand_path(File.dirname(__FILE__) + "../../spec_helper")

describe TrackingTokenLookup do
  describe "#email" do
    it "returns the correct decoded email id" do
      email = create(:email)
      user = create(:user)
      token = EmailTrackingToken.encode(user.id, email.id)
      result = TrackingTokenLookup.new(token)
      result.email.should == email
    end

    it "returns nil when given an invalid token" do
      token = EmailTrackingToken.encode(100, 250)
      result = TrackingTokenLookup.new(token)
      result.email.should be_nil
    end

    it "returns nil when given no token" do
      result = TrackingTokenLookup.new(nil)
      result.email.should be_nil
    end
  end

  describe "#user" do
    it "returns the correct decoded user id" do
      email = create(:email)
      user = create(:user)
      token = EmailTrackingToken.encode(user.id, email.id)
      result = TrackingTokenLookup.new(token)
      result.user.should == user
    end

    it "returns nil when given an invalid token" do
      token = EmailTrackingToken.encode(100, 250)
      result = TrackingTokenLookup.new(token)
      result.user.should be_nil
    end

    it "returns nil when given no token" do
      result = TrackingTokenLookup.new(nil)
      result.user.should be_nil
    end
  end

  describe "#valid?" do
    it "returns true when user and email are found" do
      email = create(:email)
      user = create(:user)
      token = EmailTrackingToken.encode(user.id, email.id)
      result = TrackingTokenLookup.new(token)
      result.valid?.should be_truthy
    end

    it "returns false when user is not found" do
      email = create(:email)
      token = EmailTrackingToken.encode(5, email.id)
      result = TrackingTokenLookup.new(token)
      result.valid?.should be_falsey
    end

    it "returns false when user and email are not found" do
      result = TrackingTokenLookup.new(nil)
      result.valid?.should be_falsey
    end
  end

  describe "#valid_source_token?" do
    it "returns true when acquisition_source" do
      user = create(:user)
      source = create(:acquisition_source)
      token = EmailTrackingToken.encode_with_source(source.id)
      result = TrackingTokenLookup.new(token)
      expect(result).to be_valid_source_token
    end

    it "returns false when invalid token" do
      result = TrackingTokenLookup.new('sdfssds')
      expect(result).to_not be_valid_source_token
    end
  end
end
