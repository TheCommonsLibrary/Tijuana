require 'spec_helper'

describe EmailTargetTrackingLog do

  describe ".generate_token" do
    it "should generate a url safe token using the UserEmail ID" do
      EmailTargetTrackingLog.generate_token(create(:user_email)).should_not =~ /[=& ]/
    end
  end

  describe ".decode_token" do
    let!(:user_email){ create(:user_email) }
    let!(:token){ EmailTargetTrackingLog.generate_token(user_email) }

    it "should not raise if fake token" do
      EmailTargetTrackingLog.decode_token('sdfs').should be_nil
    end

    it "should successfully decode a generated token" do
      EmailTargetTrackingLog.decode_token(token).should == user_email.id
    end
  end
end
