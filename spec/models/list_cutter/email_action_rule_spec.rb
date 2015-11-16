require File.expand_path(File.dirname(__FILE__) + "../../../spec_helper")

describe ListCutter::EmailActionRule do
  without_transactional_fixtures do
    before(:each) do
      @user = create(:user)
      @user1 = create(:user)
      @user2 = create(:user)
      @email1 = create(:email)
      @push1 = @email1.blast.push
      @email2 = create(:email)
      @push2 = @email2.blast.push
    end
    
    it "should return the users who received the given emails across multiple pushes" do
      with_push_table(@push1, @push2) do
        Push.log_activity!(UserActivityEvent::Activity::EMAIL_CLICKED, @user, @email1)
        Push.log_activity!(UserActivityEvent::Activity::EMAIL_CLICKED, @user1, @email2)
    
        rule = ListCutter::EmailActionRule.new(:email_id => "#{@email1.id},#{@email2.id}", :action => UserActivityEvent::Activity::EMAIL_CLICKED)
        user_ids = rule.to_relation.all.map(&:id)
        user_ids.size.should eql 2
        user_ids.should include(@user1.id,@user.id)
      end
    end

    it "should return the users who received the given emails from a single push" do
      blast = create(:blast, :push => @push1)
      another_email = create(:email, :blast => blast)

      with_push_table(@push1) do
        Push.log_activity!(UserActivityEvent::Activity::EMAIL_CLICKED, @user, @email1)
        Push.log_activity!(UserActivityEvent::Activity::EMAIL_CLICKED, @user2, another_email)

        rule = ListCutter::EmailActionRule.new(:email_id => "#{@email1.id}, #{another_email.id}", :action => UserActivityEvent::Activity::EMAIL_CLICKED)
        user_ids = rule.to_relation.all.map(&:id)
        user_ids.size.should eql 2
        user_ids.should include(@user.id, @user2.id)
      end
    end

    it "should return the users who DID NOT receive the given emails across multiple pushes" do
      with_push_table(@push1, @push2) do
        Push.log_activity!(UserActivityEvent::Activity::EMAIL_CLICKED, @user, @email1)
        Push.log_activity!(UserActivityEvent::Activity::EMAIL_CLICKED, @user1, @email2)

        rule = ListCutter::EmailActionRule.new(:not => true, :email_id => "#{@email1.id}, #{@email2.id}", :action => UserActivityEvent::Activity::EMAIL_CLICKED)
        user_ids = rule.to_relation.all.map(&:id)
        user_ids.size.should eql 1
        user_ids.should include(@user2.id)
      end
    end

    it "should return the users who DID NOT receive the given emails from a single push" do
      blast = create(:blast, :push => @push1)
      another_email = create(:email, :blast => blast)

      with_push_table(@push1) do
        Push.log_activity!(UserActivityEvent::Activity::EMAIL_CLICKED, @user, @email1)
        Push.log_activity!(UserActivityEvent::Activity::EMAIL_CLICKED, @user1, another_email)

        rule = ListCutter::EmailActionRule.new(:not => true, :email_id => "#{@email1.id}, #{another_email.id}", :action => UserActivityEvent::Activity::EMAIL_CLICKED)
        user_ids = rule.to_relation.all.map(&:id)
        user_ids.size.should eql 1
        user_ids.should include(@user2.id)
      end
    end
  end
end