require File.expand_path(File.dirname(__FILE__) + "../../../spec_helper")

describe Admin::MergesController do
  
  before :each do
    sign_in create(:admin_user)
  end

  describe "#update_whitelist" do
    context "with valid password" do
      it "should update the whitelist" do
        put :update_whitelist, merge_tokens: " token\ntrailing-space ", password: 'password'
        Setting[:whitelist_merge_tokens].should == "token\ntrailing-space"
      end
    end

    context "with invalid password" do
      before { Setting[:whitelist_merge_tokens] = 'default' }

      it "should not update whitelist" do
        put :update_whitelist, merge_tokens: " token\ntrailing-space ", password: 'invalid'
        Setting[:whitelist_merge_tokens].should == "default"
      end
    end
  end

  describe "#create" do
    before do
      Setting[:whitelist_merge_tokens] = "join\ncache"
    end

    context "invalid request" do
      it "should not create the merge or any records" do
        post :create, params: {name: 'name', join_key: '', join_field_name: 'newfield', description: 'newdesc', join_cache_key: 'cache'} # missing join key
        Merge.count.should == 0
        MergeRecord.count.should == 0
      end

      it "does not allow the creation of a merge with the same name" do
        create(:merge, name: 'taken name', join_key: 'join', join_field_name: 'field')
        post :create, params: {name: 'taken name', join_key: 'join', join_field_name: 'newfield', description: 'newdesc', join_cache_key: 'cache'} 
        Merge.count.should == 1
      end

      it "should not create merge if a header matching the join field cannot be found" do
        post :create, {merge: {name: 'name', join_key: 'join', join_field_name: 'DOESNOTEXIST', description: 'desc', join_cache_key: 'cache'}, upload_file: fixture_file_upload('/files/blast_merge_data.csv', 'text/csv')}
        assigns(:merge).errors.detect {|e| e.to_s.match /Unable to find matching header/}.should_not be_nil
        Merge.count.should == 0
        MergeRecord.count.should == 0
        response.should render_template("new")
      end

      context "empty file uploaded" do
        it "should not create any records" do
          post :create, {merge: {name: 'name', join_key: 'join', join_field_name: 'DOESNOTEXIST', description: 'desc', join_cache_key: 'cache'}, upload_file: fixture_file_upload('/files/empty_file.csv', 'text/csv')}
          Merge.count.should == 0
          MergeRecord.count.should == 0
        end
      end

      context "no file uploaded" do
        it "should not create any records" do
          post :create, {merge: {name: 'name', join_key: 'join', join_field_name: 'DOESNOTEXIST', description: 'desc', join_cache_key: 'cache'}, upload_file: nil}
          Merge.count.should == 0
          MergeRecord.count.should == 0
        end
      end
    end

    context "valid request" do
      it "should create the merge and its records and clear the cache" do
        post :create, {merge: {name: 'name', join_key: 'join', join_field_name: 'ELECTORATE', description: 'desc', join_cache_key: 'cache'}, upload_file: fixture_file_upload('/files/blast_merge_data.csv', 'text/csv')}
        Merge.count.should == 1
        merge = Merge.first
        merge.join_key.should == 'join'
        merge.join_field_name.should == 'ELECTORATE'
        merge.description.should == 'desc'
        merge.join_cache_key.should == 'cache'

        assert_merge_record_from_file
      end

      it "should handle blank headers" do
        post :create, {merge: {name: 'name', join_key: 'join', join_field_name: 'ELECTORATE', description: 'desc', join_cache_key: 'cache'}, upload_file: fixture_file_upload('/files/blast_merge_data_spaces.csv', 'text/csv')}
        assert_merge_record_from_file
      end
    end
  end

  def assert_merge_record_from_file
    MergeRecord.count.should == 7
    MergeRecord.where('name = "HOSPITAL NAME"').first.value.should == 'St George Hospital'
    MergeRecord.where('name = "FUNDING CUTS"').first.value.should == '5555'
    MergeRecord.where('name = "BED LOSSES"').first.value.should == '34'
    MergeRecord.where('name = "ELECTORATE"').first.value.should == 'Sydney'
    MergeRecord.where('name = "PETITION LINK"').first.value.should == 'https://www.communityrun.org.au/efforts/new?slug=st-george%20hospital'
    MergeRecord.where('name = "MP NAME"').first.value.should == 'terri jones'
    MergeRecord.where('name = "nurses number"').first.value.should == '4324'
  end

  describe "#update" do

    let!(:merge) { create(:merge_with_whitelist, updated_at: 1.day.ago) }
    let!(:merge_record) { create(:merge_record, merge: merge) }

    context "invalid merge paramters" do
      it "should not delete merge records if the merge is not valid" do
        put :update, id: merge.id, merge: {join_key: '', name: 'name', join_field_name: 'field', join_cache_key: ''}
        Merge.count.should == 1
        Merge.first.name.should == 'hospitals'
        MergeRecord.count.should == 1
        MergeRecord.first.name.should == 'name'

        response.should render_template(:edit)
      end
    end

    context "valid merge paramters" do
      context "no merge records uploaded" do
        it "should update updated_at field, invalidate cache but not delete records" do
          updated_at = merge.updated_at
          MergeCache.should_receive(:clear).with(merge)

          put :update, id: merge.id, merge: {join_key: 'postcode.electorates.first.name', name: 'new name', join_field_name: 'field', join_cache_key: ''}
          Merge.count.should == 1
          Merge.first.name.should == 'new name'
          MergeRecord.count.should == 1
          MergeRecord.first.name.should == 'name'
          merge.reload
          merge.updated_at.to_i.should > updated_at.to_i

          response.should redirect_to(admin_merges_path)
        end
      end

      context "only merge records uploaded" do
        it "should invaldiate cache, updated merge.updated_at and delete and repopulate the merge records" do
          updated_at = merge.updated_at
          MergeCache.should_receive(:clear).with(merge)

          put :update, id: merge.id, merge: {join_key: merge.join_key, name: merge.name, join_field_name: merge.join_field_name}, upload_file: fixture_file_upload('/files/blast_merge_data.csv', 'text/csv')
          Merge.count.should == 1

          merge.reload
          merge.updated_at.to_i.should > updated_at.to_i
          assert_merge_record_from_file

          response.should redirect_to(admin_merges_path)
        end
      end
    end
  end
end
