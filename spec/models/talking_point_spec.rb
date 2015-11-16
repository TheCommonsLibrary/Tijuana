require 'spec_helper'

describe TalkingPoint do

  describe "#empty" do
    before(:each) do
      @tp = TalkingPoint.new
    end

    it "should be empty to start" do
      @tp.empty?.should be true
    end

    it "should not be empty with short description" do
      @tp.short_description = "asdfasdf"
      @tp.empty?.should be false
    end

    it "should not be empty with long description" do
      @tp.long_description = "asdfasdf"
      @tp.empty?.should be false
    end
  end
end
