require File.dirname(__FILE__) + '/../spec_helper.rb'

describe TellAFriendModule do
  
  def validated_tell_a_friend_module(attrs)
    tafm = create(:tell_a_friend_module)
    tafm.update_attributes attrs
    tafm.valid?
    tafm
  end
  
  describe "validation" do
    it "should require a title between 3 and 128 characters" do
      validated_tell_a_friend_module(:title => "Save the kittens!").should be_valid
      validated_tell_a_friend_module(:title => "X" * 128).should be_valid
      validated_tell_a_friend_module(:title => "X" * 129).should_not be_valid
      validated_tell_a_friend_module(:title => "AB").should_not be_valid
    end
  end
  
  describe "defaults" do
    it "should have appropriate defaults" do
      tafm = TellAFriendModule.new
      tafm.title.should == "Tell your friends!"
      tafm.content.should == "Your friends would probably like to check this out, why don't you share it with them?"
    end
  end
end
