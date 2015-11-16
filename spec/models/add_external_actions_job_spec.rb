require File.expand_path(File.dirname(__FILE__) + "../../spec_helper")

describe AddExternalActionsJob do
  without_transactional_fixtures do
    before(:each) do
      @page = create(:page_with_parent)
      @list = List.new
      @list.set_email_domain_rule(:domain => "@pie.com")
    end

    it "#perform should add action records and destroy @list" do
      u1 = create(:user, :email=>'apple@pie.com')
      u2 = create(:user, :email=>'strawberry@pie.com')
      u3 = create(:user, :email=>'strawberry@other.com')

      @list.filter_by_rules
      job = AddExternalActionsJob.new(@list, @page)
      job.perform

      has_taken_external_action(u1).should be true
      has_taken_external_action(u2).should be true
      has_taken_external_action(u3).should be false
      @list.destroyed?.should be true
    end

    it "should not add duplicate user activity events" do
      u1 = create(:user, :email=>'apple@pie.com')
      @list.filter_by_rules
      job = AddExternalActionsJob.new(@list, @page)
      job.perform
      job.perform
      u1.user_activity_events.where(:activity => :external_action).count.should == 1
    end
  end

  def has_taken_external_action(user)
    UserActivityEvent.find_by_user_id_and_activity(user.id, UserActivityEvent::Activity::EXTERNAL_ACTION) != nil
  end

end
