require File.expand_path(File.dirname(__FILE__) + "../../spec_helper")

describe Ability do

  context "member" do

    let (:user) { create(:user) }
    let (:ability) { Ability.new(user) }

    it "allows management of a user-event when it's a new record" do
      event = build(:event)
      ability.can?(:manage, event).should == true
    end

    it "disallows creating a new admin-managed event" do
      event = build(:admin_managed_event)
      ability.can?(:update_host, event).should == false
    end

    it "disallows management of an admin-managed event even if you are the host" do
      event = create(:admin_managed_event, host: user)
      ability.can?(:manage, event).should == false
    end

    it "allows management of an event if you are the host on a non admin-managed event" do
      event = create(:event, host: user)
      ability.can?(:manage, event).should == true
    end

    it "disallows editing the host of an already created event" do
      event = create(:event)
      ability.can?(:update_host, event).should == false
    end

    it "allows creating a new non admin-managed event" do
      event = build(:event)
      ability.can?(:update_host, event).should == true
    end
  end

  context "admin" do
    let :admin do create(:user, is_admin: true) end
    let :ability do Ability.new(admin) end    

    it "allows management of an admin-managed event if you are an admin" do
      event = create(:admin_managed_event)
      ability.can?(:manage, event).should == true
    end

    it "allows management of an non admin-managed event if you are an admin" do
      event = create(:event)
      ability.can?(:manage, event).should == true
    end

    it "allows editing the host of an event" do
      event = create(:event)
      ability.can?(:update_host, event).should == true
    end
  
  end

end