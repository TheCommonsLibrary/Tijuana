require File.expand_path(File.dirname(__FILE__) + "../../spec_helper")

describe MergeToken do

  describe ".valid_eval?" do
    context "with valid tokens" do
      before(:each) { Setting[:whitelist_merge_tokens] = "donation.first\nfirst_name" }

      specify {MergeToken.valid_eval?("merge('hospital', 'name')").should be_truthy }
      specify {MergeToken.valid_eval?("donation.first").should be_truthy }
      specify {MergeToken.valid_eval?("first_name").should be_truthy }
    end

    context "with invalid tokens" do
      specify { MergeToken.valid_eval?('merge("hospital", "name"); ActiveRecord::Base.sql.execute("drop database")').should be_falsey }
    end
  end

  describe ".remove_comments" do
    specify { MergeToken.send(:remove_comments, "a#comment").should == ['a'] }
    specify { MergeToken.send(:remove_comments, "a#comment\nb").should == ['a', 'b'] }
    specify { MergeToken.send(:remove_comments, " a #comment\n b ").should == ['a', 'b'] }
  end
end
