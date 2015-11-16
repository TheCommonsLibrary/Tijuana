require 'spec_helper'

describe Mergeable do
  let!(:electorate) {create(:electorate)}
  let!(:postcode) {create(:postcode)}
  let(:user) {create(:user)}
  let!(:merge) {create(:merge_with_whitelist)}

  before(:each) do 
    Setting[:whitelist_merge_tokens] = "electorate.name#{Setting[:whitelist_merge_tokens]}"
    user.update_attribute(:postcode_id, postcode.id)
    postcode.electorates << electorate
    postcode.save!
    Rails.cache.clear
  end

  describe '#merge' do

    specify { user.merge('hospitals', 'i dont exist').should be_nil }
    specify { user.merge('i dont exist', 'name').should be_nil }

    context "keys not on whitelist on whitelist" do
      it "should raise an exception" do
        Setting[:whitelist_merge_tokens] = ""
        expect{ user.merge('hospitals', 'name')}.to raise_exception(NotWhitelisted)

        Setting[:whitelist_merge_tokens] = "postcode.electorates.first.name\npostcode_id"
        merge.update_attributes!({join_cache_key: 'postcode_id'})
        Setting[:whitelist_merge_tokens] = "postcode.electorates.first.name"
        expect{ user.merge('hospitals', 'name')}.to raise_exception(NotWhitelisted)
      end
    end

    context "with valid merge key" do
      let!(:merge_record_name) {create(:merge_record, merge: merge, join_id: electorate.name)}

      it "should return the merge value" do
        user.merge('hospitals', 'name').should == 'St George'
      end
    end

    context "without a cache key" do
      let!(:merge_record) { create(:merge_record, join_id: electorate.name, name: 'NAME', value: 'St George', merge: merge) }
      before { merge.update_attributes({join_cache_key: ''}) }
      it "should retrieve the merge value" do
        user.merge('hospitals', 'name').should == 'St George'
      end
    end
  end
end
