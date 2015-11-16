require File.expand_path(File.dirname(__FILE__) + "../../spec_helper")

describe DonationHelper do
  include VanityTestHelper

  describe '#show_all_amounts?' do
    context "no amounts with asterixes" do
      it "should be true" do
        amounts = ['1', '10', '20', '50']
        helper.show_all_amounts?(amounts).should be true
      end
    end

    context "amounts with asterixes" do
      it "should be false" do
        amounts = ['1', '10*', '20*', '50', '100*']
        helper.show_all_amounts?(amounts).should be false
      end
    end
  end

end
