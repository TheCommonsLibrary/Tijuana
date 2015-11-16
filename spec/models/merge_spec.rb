require File.expand_path(File.dirname(__FILE__) + "../../spec_helper")

describe Merge do
  let(:merge) { build(:merge_with_whitelist) }

  describe "validations" do
    it "should not allow merges with the same name" do
      create(:merge_with_whitelist)
      expect{create(:merge_with_whitelist, name: 'HOSPITALS')}.to raise_exception(ActiveRecord::RecordInvalid)
    end

    it "should require the join_field_name, name, join_key" do
      merge.attributes = {join_key: '', name: '', join_field_name: ''}
      merge.valid?.should == false
      merge.errors[:join_key].to_s.should match(/can't be blank/)
      merge.errors[:name].to_s.should match(/can't be blank/)
      merge.errors[:join_field_name].to_s.should match(/can't be blank/)
    end

    describe "#keys_are_on_whitelist" do
      context "keys not on whitelist" do
        before { Setting[:whitelist_merge_tokens] = "" }

        it "should add an error" do
          merge.valid?.should == false
          merge.errors[:join_key].to_s.should match(/not whitelisted/)
          merge.errors[:join_cache_key].should_not be_empty
        end
      end

      context "keys on whitelist" do
        before { Setting[:whitelist_merge_tokens] = "postcode.electorates.first.name\npostcode_id" }
        specify {merge.valid?.should == true}
      end
    end
  end


  it "should destroy dependent merge records when the merge is destroyed" do
    Setting[:whitelist_merge_tokens] = "postcode.electorates.first.name\npostcode_id"
    merge.save!
    create(:merge_record, join_id: '1', name: 'name', value: 'value', merge: merge)
    another_merge = create(:merge, join_key: 'postcode_id', name: 'another merge', join_field_name: 'field', join_cache_key: '')
    create(:merge_record, join_id: '2', name: 'name', value: 'another value', merge: another_merge)

    merge.destroy

    Merge.count.should == 1
    Merge.first.name.should == 'another merge'
    MergeRecord.count.should == 1
    MergeRecord.first.value.should == 'another value'
  end
end
