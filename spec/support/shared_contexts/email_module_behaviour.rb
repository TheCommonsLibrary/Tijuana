require "set"

shared_examples_for "an email module" do

  describe 'body signature' do
    let(:email_module) { described_class.new }
    let!(:user) {create(:user, :email => 'email@example.com')}
    let(:user_email) {UserEmail.new(body: 'a body')}

    before do
      user_email.stub(:send!)
      email_module.stub(:user_email).and_return(user_email)
      email_module.stub(:body_signature).and_return('this is a body signature')
    end

    context 'email is valid' do
      it 'adds a signature to the body before sending the email' do
        email_module.stub(:create_action).and_return(true)
        email_module.take_action(user, nil)
        user_email.body.should include('this is a body signature')
      end
    end

    context 'email is not valid' do
      it 'does not add a signature to the body' do
        email_module.stub(:create_action).and_return(false)
        email_module.take_action(user, nil)
        email_module.user_email.body.should_not include('this is a body signature')
      end
    end
  end

  describe "email 'from' field", delay_jobs: false do

    context "'from' field is invalid" do
      it "should rewrite from field and set 'reply-to' field to actual address" do
        email_module = create(described_class.name.underscore)
        user_email = create(:user_email)
        user = create(:user, email: 'sender@yahoo.com')
        page = create(:page_with_parent)
        email_module.stub(:user_email).and_return(user_email)
        AppConstants.stub(:invalid_from_email_domain).and_return(['yahoo.com', 'aol.com'])
        email_module.take_action(user, page)

        ActionMailer::Base.deliveries.last.from.should == ['sender@yahoo.com.invalid']
        ActionMailer::Base.deliveries.last.reply_to.should == ['sender@yahoo.com']
      end
    end
  end
end
