require 'spec_helper'

def nb_tags(user)
  resp = NationBuilder::Api.call_api :people, :match, email: user.email
  resp["person"] && resp["person"]["tags"]
end

def recordable_random_token
  # a random token based on a network request, recordable by vcr
  Digest::MD5.hexdigest open("https://www.google.com.au") {|r| r.meta["date"]}.to_s
end

describe NationBuilder::SyncTagsFromTjToNbService do
  describe "with a user that hasn't been synced before but matches an email in NB" do
    let(:sync_tag){ 'tag_to_sync' }
    let!(:user){ 
      allow_any_instance_of(NationBuilder::SyncUserFromTjToNbService).to receive(:sync!)
      create(:user, email: "cate@example.com", updated_at: 4.days.ago)
    }
    before{
      user.tag_list.add(sync_tag)
      user.save!
    }

    it 'should update the user record and sync the whole user' do
      NationBuilder::SyncTagsFromTjToNbService.new.sync_without_delay! [sync_tag]
      user.reload
      expect(user.updated_at.to_date).to eq(Date.today)
    end
  end
 
  context '', delay_jobs: false do
    xit "should sync tags without error", :vcr do
      token = recordable_random_token
      cate_community = create :user_for_nation_builder, :email => "cate#{token}@example.com"
      cate_community.update_attributes :tag_list => "random sync"
      NationBuilder::SyncTagsFromTjToNbService.new.sync! ["random sync"]
      NationBuilder::SyncTagsFromTjToNbService.new.sync! ["another sync"]
      nb_tags(cate_community).should == ["random sync", "another sync"]
    end

    it "should not do anything if tag does not end with sync" do
      NationBuilder::Api.should_not_receive(:call_api)
      NationBuilder::SyncTagsFromTjToNbService.new.sync! ["some tag"]
    end

    it "should sync only the tags that ends in sync" do
      service = NationBuilder::SyncTagsFromTjToNbService.new
      service.should_receive(:sync_users_who_arent_in_nb)
      service.should_receive(:tag_users_already_in_nb)
      service.sync! ["some tag", "please_sync"]
    end
  end
end
