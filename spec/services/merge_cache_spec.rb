require 'spec_helper'

describe MergeCache do
  let!(:postcode) {create(:postcode, number: '2000')}
  let!(:user) {create(:user, postcode: postcode)}
  let(:merge){ create(:merge, name: 'mymerge', join_key: 'postcode.electorates.first.name', join_field_name: 'ELECTORATE', join_cache_key: 'postcode_id') }

  before(:each) do
    Setting[:whitelist_merge_tokens] = "postcode.electorates.first.name\npostcode_id\npostcode.id\npostcode.number\nlast_name"
    Rails.cache.clear
    electorate = create(:electorate, name: 'DICKSON')
    postcode.electorates << electorate
    postcode.save!
    create(:merge_record, join_id: 'DICKSON', name: 'NAME', value: 'St George', merge: merge)
  end

  def update_merge_data
    db_merge = Merge.find_by_name 'mymerge'
    db_merge.join_key = 'postcode.number'
    db_merge.join_cache_key = 'postcode.id'
    db_merge.join_field_name = 'POSTCODE_NUMBER'
    db_merge.save!

    MergeRecord.delete_all
    create(:merge_record, join_id: '2000', name: 'NAME', value: 'RPA', merge: db_merge)
  end

  it "should not hit the db when a cached version is available" do
    cached_merge = MergeCache.fetch_merge 'mymerge'
    cached_merge.join_key.should == 'postcode.electorates.first.name'
    cached_merge.join_field_name.should == 'ELECTORATE'
    cached_merge.join_cache_key.should == 'postcode_id'
    cached_join_id = MergeCache.fetch_join_id(user, cached_merge)
    cached_join_id.should == 'DICKSON'
    MergeCache.fetch_merge_value(cached_merge, cached_join_id, 'NAME').should == 'St George'

    Merge.should_not_receive(:find_by_name)
    user.should_not_receive(:postcode)
    Postcode.any_instance.should_not_receive(:electorates)

    cached_merge = MergeCache.fetch_merge 'mymerge'
    cached_join_id = MergeCache.fetch_join_id(user, cached_merge)
    cached_merge.should_not_receive(:merge_records)
    MergeCache.fetch_merge_value(cached_merge, cached_join_id, 'NAME').should == 'St George'
  end
  
  it "should retrieve fresh data when the cache is cleared" do
    #ensure cache is populated first
    cached_merge = MergeCache.fetch_merge 'mymerge'
    cached_join_id = MergeCache.fetch_join_id(user, cached_merge)
    MergeCache.fetch_merge_value(cached_merge, cached_join_id, 'NAME').should == 'St George'

    Timecop.travel(1.day.from_now) do
      update_merge_data

      cached_merge = MergeCache.fetch_merge 'mymerge'
      cached_merge.join_key.should == 'postcode.electorates.first.name'
      cached_merge.join_field_name.should == 'ELECTORATE'
      cached_merge.join_cache_key.should == 'postcode_id'
      cached_join_id = MergeCache.fetch_join_id(user, cached_merge)
      cached_join_id.should == 'DICKSON'
      MergeCache.fetch_merge_value(cached_merge, cached_join_id, 'NAME').should == 'St George'

      MergeCache.clear(merge)

      fresh_merge = MergeCache.fetch_merge 'mymerge'
      fresh_merge.join_key.should == 'postcode.number'
      fresh_merge.join_field_name.should == 'POSTCODE_NUMBER'
      fresh_merge.join_cache_key.should == 'postcode.id'
      fresh_join_id = MergeCache.fetch_join_id(user, fresh_merge)
      fresh_join_id.should == '2000'
      MergeCache.fetch_merge_value(fresh_merge, fresh_join_id, 'NAME').should == 'RPA'
    end
  end

  it "should not cache join_id if no join_cache_key has been specified" do
    merge = create(:merge, join_key: 'postcode_id', join_field_name: 'field', name: 'themerge')
    MergeCache.fetch_join_id(user, merge)
    
    merge.join_key = 'last_name'
    merge.save!

    MergeCache.fetch_join_id(user, merge).should == user.last_name
  end

  it "should ignore the cache key if none has been specified" do
    merge = create(:merge, join_key: 'postcode_id', join_field_name: 'field', name: 'themerge', join_cache_key: '')
    MergeCache.fetch_join_id(user, merge).should == user.postcode_id
  end
end
