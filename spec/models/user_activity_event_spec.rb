require File.expand_path(File.dirname(__FILE__) + "../../spec_helper")

describe UserActivityEvent do
  before(:each) do
    @user = create(:user)
    @petition_module = create(:petition_module, :public_activity_stream_template => "Someone signed!")
    @signature = create(:petition_signature, :user => @user, :content_module => @petition_module)
    @page = create(:page_with_parent)
    @email = create(:email)
    @source = 'test'
    @acquisition_source = create(:acquisition_source)
  end

  describe "importing external events" do
    it "should record event" do
      page = create(:page_with_parent, name: 'Saving the bees')
      event = UserActivityEvent.external_action!(@user.id, page)
      event.new_record?.should be false
      event.activity.should == :external_action
      event.public_stream_html.should include("took action for")
      event.user_id.should == @user.id
      event.page_id.should == page.id
      event.page_sequence_id.should == page.page_sequence.id
      event.campaign_id.should == page.page_sequence.campaign_id
      event.campaign_id.should > 0
    end
  end
  
  describe "creating a subscribed event" do
    it "creates an event without signup ask/page information" do
      event = UserActivityEvent.subscribed!(@user)
      event.activity.should == :subscribed
      event.user.should == @user
      event.content_module.should == nil
      event.page.should == nil
      event.public_stream_html.should == '<span class="name">A new member</span> subscribed to GetUp!'
    end
    
    it "creates an event including signup ask/page information" do
      event = UserActivityEvent.subscribed!(@user, @page, @petition_module)
      event.activity.should == :subscribed
      event.user.should == @user
      event.content_module.should == @petition_module
      event.content_module_type.should == "PetitionModule"
      event.page.should == @page
      event.page_sequence.should == @page.page_sequence
      event.campaign.should == @page.page_sequence.campaign
      event.public_stream_html.should == '<span class="name">A new member</span> subscribed to GetUp!'
    end

    it "creates an event including signup ask/page/source information" do
      event = UserActivityEvent.subscribed!(@user, @page, @petition_module, nil, 'facebook')
      event.activity.should == :subscribed
      event.user.should == @user
      event.content_module.should == @petition_module
      event.content_module_type.should == "PetitionModule"
      event.page.should == @page
      event.page_sequence.should == @page.page_sequence
      event.campaign.should == @page.page_sequence.campaign
      event.source.should == 'facebook'
      event.public_stream_html.should == '<span class="name">A new member</span> subscribed to GetUp!'
    end

    it "sync new user from NB to TJ" do
      event = UserActivityEvent.subcribe_user_created_by_nb!(@user)
      event.activity.should == :subscribed
      event.user.should == @user
      event.source.should == 'nb'
      event.public_stream_html.should == '<span class="name">A new member</span> created by Nation Builder'
    end
  end
  
  it "creates an action_taken event" do
    event = UserActivityEvent.action_taken!(@user, @page, @petition_module, @signature, @email, @source, @acquisition_source)
    event.activity.should == :action_taken
    event.user.should == @user
    event.user_response.should == @signature
    event.content_module.should == @petition_module
    event.content_module_type.should == "PetitionModule"
    event.page.should == @page
    event.page_sequence.should == @page.page_sequence
    event.campaign.should == @page.page_sequence.campaign
    event.public_stream_html.should == "Someone signed!"
    event.source.should == @source
    event.acquisition_source.should == @acquisition_source
  end

  it "creates an email clicked event" do
    @email = create(:email)
    push = @email.blast.push
    with_push_table(push) do
      UserActivityEvent.email_clicked!(@user, @email)
      push.count_by_activity(:email_clicked).should eql 1
    end
  end

  without_transactional_fixtures do
    it "creates an email viewed event" do
      @email = create(:email)
      push = @email.blast.push
      with_push_table(push) do
        UserActivityEvent.email_viewed!(@user, @email)
        push.count_by_activity(:email_viewed).should eql 1
      end
    end
  end

  it "creates an agra unsubscribed event" do
    @email = create(:email)
    unsubscribe = create(:unsubscribe, email: @email, user: @user, community_run: true)
    event = UserActivityEvent.agra_unsubscribed!(@user, unsubscribe, @email)
    event.activity.should == :agra_unsubscribed
    event.user.should == @user
    event.email.should == @email
  end

  it "creates an unsubscribed event" do
    @email = create(:email)
    unsubscribe = create(:unsubscribe, email: @email, user: @user)
    event = UserActivityEvent.unsubscribed!(@user, unsubscribe, @email)
    event.activity.should == :unsubscribed
    event.user.should == @user
    event.email.should == @email
  end

  it "creates a get together event attend registration event" do
    @get_together_event = create(:event)
    event = UserActivityEvent.registered_to_attend!(@user, @get_together_event, @email)
    event.activity.should == :action_taken
    event.user.should == @user
    event.email.should == @email
    event.get_together_event.should == @get_together_event
  end

  it "creates a get together event host registration event" do
    @get_together_event = create(:event)
    event = UserActivityEvent.registered_to_host!(@user, @get_together_event)
    event.activity.should == :action_taken
    event.user.should == @user
    event.get_together_event.should == @get_together_event  
  end

  it 'creates a get together event creation with tracking token registration event' do
    @get_together_event = create(:event)
    event = UserActivityEvent.registered_create_event_from_email!(@user, @get_together_event, @email)
    event.activity.should == :action_taken
    event.user.should == @user
    event.email.should == @email
    event.get_together_event.should == @get_together_event
    event.public_stream_html.blank?.should == true
  end

  it "should not create a public stream for event activities which is too long" do
    user = create(:user, first_name: 'Macca the man Macdonald')
    get_together = create(:get_together, name: 'Important election futures get together')
    get_together_event = create(:event, name: 'this name is crazy long for this event but it goes in here anyway because we are testing')
    event = UserActivityEvent.registered_to_host!(user, get_together_event)
    event.public_stream_html.should == '<span class="name">Macca The Man Macdonald</span> is hosting <a href="/events/all-for-the-kittens-this-name-is-crazy-long-for-this-event-but-it-goes-in-here-anyway-because-we-are-testing">this name is crazy long for this even...</a>'

    event = UserActivityEvent.registered_to_attend!(user, get_together_event, @email)
    event.public_stream_html.should == '<span class="name">Macca The Man Macdonald</span> is attending <a href="/events/all-for-the-kittens-this-name-is-crazy-long-for-this-event-but-it-goes-in-here-anyway-because-we-are-testing">this name is crazy long for this even...</a>'
  end

  describe "#agra_take_action!" do
    it "should create an agra action taken event" do
      user = create(:user)
      campaign = create(:campaign)
      push = create(:push, campaign: campaign)
      blast = create(:blast, push: push)
      email = create(:email, blast: blast)
      agra_action = create(:agra_action_signer, user: user, role: 'creator')

      event = UserActivityEvent.agra_take_action!(user, email, agra_action)
      event.user.should == user
      event.activity.should == :action_taken
      event.campaign.should == campaign
      event.user_response == agra_action
      event.email.should == email
      event.push.should == push
      event.source.should == "cr_#{agra_action.role}"
      event.public_stream_html.should == "<span class=\"name\">Member</span> created Community Run campaign <a href='https://www.communityrun.org/petitions/agra-slug'>Agra Slug</a>"
    end
    
    it "should create an agra action taken if email is not specified" do
      user = create(:user)
      agra_action = create(:agra_action_signer, user: user, role: 'creator')
      
      event = UserActivityEvent.agra_take_action!(user, nil, agra_action)
      
      event.user.should == user
      event.activity.should == :action_taken
      event.user_response == agra_action
      event.email.should == nil
      event.push.should == nil
      event.campaign.should == nil
    end
    
    it 'should truncate community run campaign name to keep public html under 255' do
      user = create(:user)
      agra_action = create(:agra_action_signer, user: user, role: 'creator', :slug => "here-is-my-really-awsome-campaign-with-a-really-long-name-that-will-make-a-difference-to-australia")
      
      event = UserActivityEvent.agra_take_action!(user, nil, agra_action)
      event.public_stream_html.should == "<span class=\"name\">Member</span> created Community Run campaign <a href='https://www.communityrun.org/petitions/here-is-my-really-awsome-campaign-with-a-really-long-name-that-will-make-a-difference-to-australia'>Here Is My Really Awsome Campaign Wi...</a>"
    end
  end

  describe ".email_dropped!" do

    let(:dropped_at) { 4.days.ago }
    let(:source) { 'bounce' }
    let(:user) { create(:user) }

    it "should create an email dropped event" do
      event = UserActivityEvent.email_dropped!(user, source, dropped_at)
      event.user.should == user
      event.activity.should == :email_dropped
      event.source.should == "sg_#{source}"
      event.created_at.to_date.should == dropped_at.to_date
    end
  end

  describe ".email_dropped_unless_duplicate_event!" do

    let(:dropped_at) { 5.days.ago }
    let(:source) { 'bounce' }
    let(:user) { create(:user) }

    it "should NOT create a duplicate email dropped event" do
      UserActivityEvent.email_dropped_unless_duplicate_event!(user, source, dropped_at)
      UserActivityEvent.email_dropped_unless_duplicate_event!(user, source, dropped_at)
      UserActivityEvent.email_drops.count.should == 1
    end
  end

  context "after save" do
    context "with action events" do
      it "should schedule a delayed job to recalculate member value" do
        MemberValue.should_receive(:queue_recalculate_for_user).with(@user, :external_action, nil, @page, nil)
        UserActivityEvent.external_action!(@user.id, @page)

        MemberValue.should_receive(:queue_recalculate_for_user).with(@user, :action_taken, @petition_module, @page, nil)
        UserActivityEvent.action_taken!(@user, @page, @petition_module, @signature, @email)

        agra_user = create(:user)
        MemberValue.should_receive(:queue_recalculate_for_user).with(agra_user, :action_taken, nil, nil, nil)
        UserActivityEvent.agra_take_action!(agra_user, @email, create(:agra_action_signer))

        event = create(:event)
        MemberValue.should_receive(:queue_recalculate_for_user).with(@user, :action_taken, nil, nil, event)
        UserActivityEvent.registered_to_attend!(@user, event, @email)

        event_creator = create(:user)
        event_from_email = create(:event)
        MemberValue.should_receive(:queue_recalculate_for_user).with(event_creator, :action_taken, nil, nil, event_from_email)
        UserActivityEvent.registered_create_event_from_email!(event_creator, event_from_email, @email)

        event_to_host = create(:event)
        MemberValue.should_receive(:queue_recalculate_for_user).with(@user, :action_taken, nil, nil, event_to_host)
        UserActivityEvent.registered_to_host!(@user, event_to_host)
      end
    end

    context "with non-action events" do
      it "should NOT schedule a delayed job to recalculate member value" do
        MemberValue.should_not_receive(:queue_recalculate_for_user)
        UserActivityEvent.subscribed!(@user)
        UserActivityEvent.agra_unsubscribed!(@user, nil)
        UserActivityEvent.unsubscribed!(@user, nil)
        UserActivityEvent.requested_less_email!(@user)
        UserActivityEvent.email_dropped!(@user, nil, nil)
      end
    end
  end
end
