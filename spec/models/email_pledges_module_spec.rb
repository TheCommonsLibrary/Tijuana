require 'spec_helper'

describe EmailPledgesModule do
  it_behaves_like "a talking point module", {pro_forma_prefix: 'prefix', pro_forma_suffix: 'suffix'}

  let(:email_module) { create(:email_pledges_module) }
  let!(:user) {create(:user, :email => 'email@example.com')}
  let(:user_email) {UserEmail.new(body: 'a body', content_module: email_module)}

  describe 'validation' do
    it 'requires one of the pro forma fields to be present' do
      email_module.valid?.should == true
      email_module.pro_forma_prefix = nil
      email_module.pro_forma_suffix = nil
      email_module.valid?.should == false

      email_module.pro_forma_suffix = 'suffix'
      email_module.valid?.should == true
    end
  end

  describe "target_details_or_default" do
    it "should default to 3 blank target details" do
      email_module.target_details_or_default.should == [["", ""], ["", ""], ["", ""]]
    end
  end

  describe "#update_action_attributes_and_validate" do
    it "should return the previously set targets" do
      email_module.stub(:user_email).and_return(user_email)
      target_emails = ['email1@email.com', '', 'email3@email.com', 'email4@email.com', 'email5@email.com', 'email6@email.com']
      target_names = ['name1', 'name2', '', 'name4', 'name5', 'name6']
      email_module.update_action_attributes_and_validate(target_emails: target_emails, target_names: target_names, user_email: {subject: 'subject'} )
      email_module.target_details_or_default.should == [["email1@email.com", "name1"], ["", "name2"], ["email3@email.com", ""], ["email4@email.com", "name4"], ["email5@email.com", "name5"], ["email6@email.com", "name6"] ]
    end

    it "should record all email targets and user email attributes" do
      email_module.stub(:user_email).and_return(user_email)
      target_emails = ['email1@email.com', 'email2@email.com', '', '', '', '']
      target_names = ['name1', '', '', '', '', '']
      params = {user_email: {body: 'body'},  target_emails: target_emails, target_names: target_names}
      email_module.update_action_attributes_and_validate(params)

      user_email.body.should == 'body'
      user_email.targets.should == 'email1@email.com,email2@email.com'
      email_module.target_details_or_default.should == [["email1@email.com", "name1"], ["email2@email.com", ""], ["", ""] ]
    end
  end

  describe "#take_action" do
    before(:each) do
      UserEmail.any_instance.stub(:send!)
      email_module.stub(:user_email).and_return(user_email)
      email_module.stub(:body_signature).and_return('this is a body signature')
    end

    context 'email is valid' do
      it 'adds the pro forma message and signature' do
        user_email.content_module = email_module
        user_email.user = user
        user_email.targets = 'target@target.com'

        email_module.stub(:create_action).and_return(true)
        email_module.update_action_attributes_and_validate(:user_email => {:body => "make the switch now"}, :target_names => ['buddy guy'], :target_emails => ['buddy@friend.com'])
        email_module.take_action(user, create(:page_with_parent))
        email_module.user_email.body.should match(/prefix\s*make the switch now\s*suffix\s*this is a body signature/)
      end
    end

    context 'email is not valid' do
      it 'does not add the pro forma message nor the signature' do
        email_module.stub(:create_action).and_return(false)
        email_module.take_action(user, nil)
        email_module.user_email.body.should_not include('prefix')
        email_module.user_email.body.should_not include('suffix')
        email_module.user_email.body.should_not include('this is a body signature')
      end
    end

    it 'does not allow user to set the subject' do
      email_module.default_subject = 'default subject'
      email_module.stub(:create_action).and_return(false)
      email_module.take_action(user, nil, nil, {user_email: {subject: 'new subject'}})
      email_module.user_email.subject.should == 'default subject'
    end
  end

  describe "email 'from' field", delay_jobs: false do
    before(:each) do
      ActionMailer::Base.deliveries = []
    end

    context "'from' field is invalid" do
      it "should rewrite from field and set 'reply-to' field to actual address" do
        email_module = create(described_class.name.underscore, {pro_forma_prefix: 'prefix', pro_forma_suffix: 'suffix'})
        user_email = create(:user_email)
        user = create(:user, email: 'sender@yahoo.com')
        page = create(:page_with_parent)
        email_module.stub(:user_email).and_return(user_email)
        AppConstants.stub(:invalid_email_from_domains).and_return(['yahoo.com', 'aol.com'])

        email_module.update_action_attributes_and_validate(:user_email => {:subject => "make the switch", :body => "make the switch now"}, :target_names => ['buddy guy'], :target_emails => ['buddy@friend.com'])
        email_module.take_action(user, page)

        ActionMailer::Base.deliveries.last.from.should == ['sender@yahoo.com.invalid']
        ActionMailer::Base.deliveries.last.reply_to.should == ['sender@yahoo.com']
      end
    end
  end

  describe "#take_action", delay_jobs: false do
    before(:each) do
      ActionMailer::Base.deliveries = []
    end

    it "should only send one email to each target" do
        email_module = create(described_class.name.underscore, {pro_forma_prefix: 'prefix', pro_forma_suffix: 'suffix'})
        user_email = create(:user_email)
        user = create(:user)
        page = create(:page_with_parent)
        email_module.stub(:user_email).and_return(user_email)

        email_module.update_action_attributes_and_validate(:user_email => {:subject => "make the switch", :body => "make the switch now"}, :target_names => ['buddy guy', 'friendly dude'], :target_emails => ['buddy@friend.com', 'friendly@dude.com'])
        email_module.take_action(user, page)

        ActionMailer::Base.deliveries.count.should == 2
        ActionMailer::Base.deliveries.first.to.should == ['buddy@friend.com']
        ActionMailer::Base.deliveries.last.to.should == ['friendly@dude.com']
    end
  end

  describe "#defaults" do
    it "should set appropriate defaults" do
      page = create(:page_with_parent)
      email_module = EmailPledgesModule.create!(:title => "A Title", :default_subject => "The Subject", :default_body => "The body which needs to be over 10 chars.", :pro_forma_prefix => 'prefix', :pro_forma_suffix => 'suffix')
      ContentModuleLink.create!(:page => page, :content_module => email_module)
      email_module.button_text.should eql('Send!')
      email_module.prompt_as_default?.should == true
    end
  end
end
