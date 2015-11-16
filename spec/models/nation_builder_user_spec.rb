require 'spec_helper'

describe NationBuilderUser do

  describe ".record_nationbuilder_id!" do
    let!(:matching_user){ create :user }
    let!(:nationbuilder_id){ 99999999 }

    context "with a user without a corresponding nation_builder_user record" do
      it "should create the association with the site and id details" do
        NationBuilderUser.record_nationbuilder_id! matching_user.id, nationbuilder_id
        matching_user.reload
        matching_user.nation_builder_user.nationbuilder_id.should == nationbuilder_id
        matching_user.nation_builder_user.nationbuilder_site.should == AppConstants.nationbuilder_site
      end
    end

    context "with a nation_builder_user that matches the NB id but associated with another user (possibly due to merge in NB)" do
      let!(:existing_nation_builder_user){ create :nation_builder_user, user_id: 10000, nationbuilder_id: nationbuilder_id }
      it "should update the record" do
        NationBuilderUser.record_nationbuilder_id! matching_user.id, nationbuilder_id
        existing_nation_builder_user.reload
        existing_nation_builder_user.user.should == matching_user
      end
    end
  end
end
