require 'spec_helper'

describe EmailTrackingToken do
  before do
    AppConstants.stub(:email_token_salt).and_return("this is a test")
  end

  describe "#encode" do
    it "uses a known generation algorithm" do
      EmailTrackingToken.encode(12345,67890).should eq("N8awi4l4")
    end
  end

  describe "#encode_with_source" do
    it "uses a known generation algorithm" do
      EmailTrackingToken.encode_with_source(123).should eq("rNtMtNn")
    end
  end

  describe "#decode" do
    def decode(token)
      EmailTrackingToken.decode(token)
    end

    it "handles nil & empty tokens" do
      decode(nil).should eq({})
      decode("").should eq({})
    end

    context "with a new token" do
      it "handles really long tokens that cause the hashids gem to error" do
        expect{
          decode("asdfasd3297843fasdfasdfasd3297843fasdf")
        }.to_not raise_error
      end

      it "handles malformed tokens" do
        decode("asdfasd3297843fasdf").should eq({})
      end

      it "decodes a valid token" do
        decode("5ww8qFMX9").should eq({ userid: 1466223, emailid: 1855 })
      end

      it "strips extra whitespace (which may come from emails)" do
        decode(" WkL  Xk\nSkBA ").should eq({ userid: 1333317, emailid: 2003})
      end

      it "decodes source id" do
        decode("ZnKNi1to7").should eq({ userid: 12345, emailid: 0, sourceid: 123 })
      end
    end

    context "with a legacy token" do
      it "handles really long tokens that cause the hashids gem to error" do
        expect{
          decode("dasdfasd3297843fasdfasdfasd3297843fasdf")
        }.to_not raise_error
      end

      it "handles malformed tokens" do
        decode("dasdfasd3297843fasdf").should eq({})
      end

      it "decodes a valid token" do
        decode("dXNlcmlkPTE0NjYyMjMsZW1haWxpZD0xODU1").should eq(
          { userid: 1466223, emailid: 1855 }
        )
      end

      it "strips extra whitespace (which may come from emails)" do
        decode(" dXNlc mlkPTE\nzMzMzMTcsZW   1haWxp ZD0yMDAz").should eq(
          { userid: 1333317, emailid: 2003 }
        )
      end
    end

  end
end
