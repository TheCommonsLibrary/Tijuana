require 'spec_helper'

describe ActsAsTaggableOnActiveRecordRelation do
  it "should add tag only once" do
    user = create :user

    expect do
      2.times {User.where(:id => user.id).add_tags(["bulk_tag"])}
    end.
    to change {ActsAsTaggableOn::Tagging.count}.by(1)
  end
  
  it "should add multiple tags" do
    user = create :user
    User.where(:id => user.id).add_tags ["mytag1", "mytag2"]
    user.tag_list.should == ["mytag1", "mytag2"]
  end
  
  it "should work with multiple taggable types" do
    campaign = create :campaign
    user = create :user
    Campaign.where(:id => campaign.id).add_tags ["mytag"]
    User.where(:id => user.id).add_tags ["mytag"]
    campaign.tag_list.should == ["mytag"]
    user.tag_list.should == ["mytag"]
  end
end