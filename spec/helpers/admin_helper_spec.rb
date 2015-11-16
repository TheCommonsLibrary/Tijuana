require File.expand_path(File.dirname(__FILE__) + "../../spec_helper")

describe Admin::AdminHelper do

  context "#link_to_nation_builder_user_view" do
    let(:user) { FactoryGirl.create(:user) }

    it "no nation builder id" do
      helper.link_to_nation_builder_user_view(user).should be_blank
    end

    it "has nation builder id" do
      NationBuilderUser.create(user_id:user.id, nationbuilder_id:500)
      helper.link_to_nation_builder_user_view(user).should == 
        "<a id=\"nb-link\" href=\"https://gu.nationbuilder.com/admin/signups/500\">View in NationBuilder</a>"
    end
  end
end
