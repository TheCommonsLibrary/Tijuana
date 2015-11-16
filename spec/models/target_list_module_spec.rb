require File.dirname(__FILE__) + '/../spec_helper.rb'

describe TargetListModule do
  it_behaves_like "an email module"

  describe '#take_action' do
    before :each do
      @user = create(:user)
      @page = create(:page_with_parent)
      @user_email = create(:user_email)
      subject.stub(:user_email).and_return(@user_email)
    end

    it 'should raise DuplicateActionTakenError' do
      content_module = create(:target_list_module)
      content_module_link = create(:content_module_link, content_module: content_module, page: @page)
      create(:user_email, content_module: content_module, user: @user)
      expect { content_module.take_action(@user, @page) }.to raise_error(DuplicateActionTakenError)
    end

    describe "email subject" do
      it "should send an email with default subject" do
        @user_email.should_receive(:send!)
        @user_email.subject = nil
        default_subject = 'i am the default subject'
        subject.stub(:default_subject).and_return(default_subject)

        subject.take_action(@user, @page)
        @user_email.subject.should == default_subject
      end

      it "should send email with supplied subject line" do
        @user_email.should_receive(:send!)
        subject_line = 'this is the subject'
        @user_email.subject = subject_line

        subject.take_action(@user, @page)
        @user_email.subject.should == subject_line
      end

      it 'should return false if placeholder' do
        @user_email.should_not_receive(:send!)
        @user_email.subject = nil
        default_subject = 'i am the default subject'
        subject.stub(:default_subject).and_return(default_subject)
        subject.stub(:prompt_as_placeholder?).and_return(true)
        subject.take_action(@user, @page).should be false
      end
    end

    describe "email body" do
      it "should use the supplied email body" do
        @user_email.should_receive(:send!)
        email_body = 'This is a supplied email body!!!'
        @user_email.body = email_body

        subject.take_action(@user, @page)
        @user_email.body.should include(email_body)
      end

      it "should use the default body if none has been supplied" do
        @user_email.should_receive(:send!)
        default_body = 'This is a default body for super fund!!!'
        @user_email.body = default_body

        subject.take_action(@user, @page)
        @user_email.body.should include(default_body)
      end

      it 'should return false if placeholder' do
        @user_email.should_not_receive(:send!)
        @user_email.body = nil
        default_body = 'i am the default subject'
        subject.stub(:default_body).and_return(default_body)
        subject.stub(:prompt_as_placeholder?).and_return(true)
        subject.take_action(@user, @page).should be false
      end
    end
  end

  describe 'target email list' do
    context 'valid target email list' do
      context 'with one pipe' do
        it 'should parse email and target' do
          target_list_module = TargetListModule.create(
              :title => 'Target List Target',
              :content => 'This is the content',
              :default_subject => 'This is the default subject',
              :default_body => 'This is the default body',
              :target_email_list => 'editorial@citynorthnews.com.au|Brisbane North - City-North News'
          )

          target_list_module.list_emails.values.should include 'editorial@citynorthnews.com.au'
          target_list_module.list_emails.keys.should include 'Brisbane North - City-North News'
        end
      end

      context 'with multiple pipes' do
        it 'should parse email and target' do
          target_list_module = TargetListModule.create(
              :title => 'Target List Target',
              :content => 'This is the content',
              :default_subject => 'This is the default subject',
              :default_body => 'This is the default body',
              :target_email_list => 'editorial@citynorthnews.com.au|Brisbane North - City-North News | with subtitle'
          )

          target_list_module.list_emails.values.should include 'editorial@citynorthnews.com.au'
          target_list_module.list_emails.keys.should include 'Brisbane North - City-North News | with subtitle'
        end
      end

      context 'with extra spacing' do
        it 'should parse email and target' do
          target_list_module = TargetListModule.create(
              :title => 'Target List Target',
              :content => 'This is the content',
              :default_subject => 'This is the default subject',
              :default_body => 'This is the default body',
              :target_email_list => '  editorial@citynorthnews.com.au    |   Brisbane North - City-North News           '
          )

          target_list_module.list_emails.values.should include 'editorial@citynorthnews.com.au'
          target_list_module.list_emails.keys.should include 'Brisbane North - City-North News'
        end
      end
    end

    context 'invalid target email list' do
      context 'without a pipe' do
        it 'should not parse email and target' do
          target_list_module = TargetListModule.create(
              :title => 'Target List Target',
              :content => 'This is the content',
              :default_subject => 'This is the default subject',
              :default_body => 'This is the default body',
              :target_email_list => 'editorial@citynorthnews.com.au Brisbane North - City-North News'
          )

          target_list_module.list_emails.values.should be_empty
          target_list_module.list_emails.keys.should be_empty
        end
      end

      context 'without a target' do
        it 'should not parse email and target' do
          target_list_module = TargetListModule.create(
              :title => 'Target List Target',
              :content => 'This is the content',
              :default_subject => 'This is the default subject',
              :default_body => 'This is the default body',
              :target_email_list => 'editorial@citynorthnews.com.au | '
          )

          target_list_module.list_emails.values.should be_empty
          target_list_module.list_emails.keys.should be_empty
        end
      end
    end
  end

  describe 'validation' do
    def validate_target_list_module(attrs)
      target_list_module = create(:target_list_module)
      target_list_module.update_attributes attrs
      target_list_module.valid?
      target_list_module
    end

    context 'target email list placeholder' do
      it 'should require a placeholder' do
        validate_target_list_module(target_placeholder: 'Find and select your local paper').should be_valid
        validate_target_list_module(target_placeholder: '').should_not be_valid
      end
    end

    context 'target email list' do
      it 'should split emails and targets by pipe' do
        validate_target_list_module(target_email_list: 'test1@email.com | First target').should be_valid
        validate_target_list_module(target_email_list: 'test1@email.com|First target').should be_valid
        validate_target_list_module(target_email_list: '  test1@email.com |             First target').should be_valid
        validate_target_list_module(target_email_list: 'test1@email.com|First target|subtitle').should be_valid
        validate_target_list_module(target_email_list: 'test1@email.com / First target').should_not be_valid
        validate_target_list_module(target_email_list: 'test1@email.com, First target').should_not be_valid
        validate_target_list_module(target_email_list: 'test1@email.com First target').should_not be_valid
        validate_target_list_module(target_email_list: 'test1@email.com').should_not be_valid
        validate_target_list_module(target_email_list: 'test1 @ email.com').should_not be_valid
      end

      it 'should require a valid email' do
        validate_target_list_module(target_email_list: 'test1@email.com, test2@email.com | First target').should be_valid
        validate_target_list_module(target_email_list: 'test1@email.com; test2@email.com | First target').should be_valid
        validate_target_list_module(target_email_list: 'test@email | First target').should_not be_valid
        validate_target_list_module(target_email_list: 'testemail.com | First target').should_not be_valid
        validate_target_list_module(target_email_list: 'testemail | First target').should_not be_valid
        validate_target_list_module(target_email_list: 'test1@email.com, test@email | First target').should_not be_valid
      end

      it 'should require an email and a target' do
        validate_target_list_module(target_email_list: 'test1@email.com | ').should_not be_valid
        validate_target_list_module(target_email_list: ' | My target').should_not be_valid
      end

      context 'with a valid target email list' do
        it 'should return a target email without spaces' do
          params = {
              list_target: 'First target',
              user_email: {
                  subject: 'a subject',
                  body: 'a body',
                  cc_me: 0
              }
          }
          target_list_module = create(:target_list_module, target_email_list: '    test@email.com    |First target')
          target_list_module.update_action_attributes_and_validate(params)
          target_list_module.user_email.targets.should == 'test@email.com'
        end

        it 'should select a target without spaces' do
          params = {
              list_target: 'First target',
              user_email: {
                  subject: 'a subject',
                  body: 'a body',
                  cc_me: 0
              }
          }
          target_list_module = create(:target_list_module, target_email_list: 'test@email.com|        First target       ')
          target_list_module.update_action_attributes_and_validate(params)
          target_list_module.user_email.targets.should == 'test@email.com'
        end
      end
    end
  end

  describe '#update_action_attributes_and_validate' do
    it 'should update UserEmail to be valid' do
      params = {
          list_target: 'Brisbane North - City-North News',
          user_email: {
              subject: 'a subject',
              body: 'a body',
              cc_me: 0
          }
      }
      content_module = create(:target_list_module)
      content_module.update_action_attributes_and_validate(params)
      content_module.user_email.targets.should == 'editorial@citynorthnews.com.au'
    end

    it 'should not update UserEmail' do
      params = {
          list_target: '',
          user_email: {
              subject: 'a subject',
              body: 'a body',
              cc_me: 0
          }
      }
      content_module = create(:target_list_module)
      content_module.update_action_attributes_and_validate(params)
      content_module.user_email.targets.should be_nil
    end
  end
end
