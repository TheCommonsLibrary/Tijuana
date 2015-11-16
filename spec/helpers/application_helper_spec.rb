require File.expand_path(File.dirname(__FILE__) + "../../spec_helper")

describe ApplicationHelper do
  describe "#sum_list" do

    it "should sum up all the transactions in the list" do
      donation = create(:donation)

      transactions = [Transaction.create!(:donation => donation, :successful => true, :amount_in_cents => 113 ),
                      Transaction.create!(:donation => donation, :successful => true, :amount_in_cents => 117 ),
                      Transaction.create!(:donation => donation, :successful => true, :amount_in_cents => 103)]

      helper.sum_list(transactions, :amount_in_dollars).should eql 3.33
    end
  end

  describe "#page_title" do
    it "should return page title when content for title has been set" do
      title = "don't let them get away with it"
      helper.stub(:content_for?).and_return(true)
      helper.stub(:content_for).and_return(title)
      helper.page_title.should match(title)
    end

    it "should return default title when content for title has not been set" do
      default_title = "hi there, i'm the default title"
      helper.stub(:content_for?).and_return(false)
      AppConstants.stub(:default_page_title).and_return(default_title)
      helper.page_title.should eql default_title
    end
  end

  describe '#friendly_url_from_page_sequence(page_sequence)' do
    let(:ps) { create(:page_sequence, name: 'DummyPageSequence', campaign: create(:campaign, name: 'DummyCampaign')) }

    specify { helper.friendly_url_from_page_sequence(ps).should == 'http://test.host/campaigns/dummycampaign/dummypagesequence' }
  end

  describe '#friendly_url(page)' do
    let(:ps) { create(:page_sequence, name: 'DummyPageSequence', campaign: create(:campaign, name: 'DummyCampaign')) }
    let(:page) { create(:page, page_sequence: ps) }

    specify { helper.friendly_url(page).should == 'http://test.host/campaigns/dummycampaign/dummypagesequence/unnamed-page' }
  end

  describe '#friendly_path' do
    let(:ps) { create(:page_sequence, name: 'DummyPageSequence', campaign: create(:campaign, name: 'DummyCampaign')) }
    let(:page) { create(:page, page_sequence: ps) }

    specify { helper.friendly_path(page).should == '/campaigns/dummycampaign/dummypagesequence/unnamed-page' }
  end

  describe "#reset_password_url" do
    before :each do
    end

    it "should not modify the string when in development" do
      Rails.env.stub(:production?).and_return(false)
      Rails.env.stub(:showcase?).and_return(false)

      helper.reset_password_url('myurl.com').should == 'myurl.com'
    end

    it "should prepend 'https://www.'when in production" do
      Rails.env.stub(:production?).and_return(true)
      Rails.env.stub(:showcase?).and_return(false)

      helper.reset_password_url('www.myurl.com').should == 'https://www.myurl.com'
      helper.reset_password_url('myurl.com').should == 'https://www.myurl.com'
    end

    it "should prepend 'https://' when in showcase" do
      Rails.env.stub(:production?).and_return(false)
      Rails.env.stub(:showcase?).and_return(true)

      helper.reset_password_url('showcase.myurl.com').should == 'https://showcase.myurl.com'
      helper.reset_password_url('myurl.com').should == 'https://myurl.com'
    end
  end

  describe "#body_class" do
    it "should return 'home has_navbar' for dashboard pages" do
      helper.stub(:controller).and_return(DashboardController.new)
      helper.body_class.should == "home has_navbar article"

      helper.stub(:controller).and_return(HomeController.new)
      helper.body_class.should_not == "home has_navbar"
    end

    it "should return 'article' for home and unsubscribe pages" do
      helper.stub(:controller).and_return(UnsubscribeController.new)
      helper.body_class.should == "article"

      helper.stub(:controller).and_return(HomeController.new)
      helper.body_class.should == "article"
    end

    it "should contain article for the home page and all campaign pages" do
      page_without_ask = create(:page_with_parent)
      page_with_ask = create(:page_with_parent)
      content_module = create(:petition_module)
      page_with_ask.content_modules << content_module

      helper.instance_variable_set(:@page, page_without_ask)
      helper.body_class.should include("article")

      helper.instance_variable_set(:@page, page_with_ask)
      helper.body_class.should include("article")

      helper.instance_variable_set(:@page, nil)
      helper.stub(:controller).and_return(HomeController.new)
      helper.body_class.should include("article")
    end

    it "should contain article for event pages" do
      get_together = create(:get_together)
      helper.stub(:controller).and_return(EventsController.new)
      helper.body_class.should include("article")
    end

    it "should contain article for get together pages" do
      helper.stub(:controller).and_return(GetTogethersController.new)
      helper.body_class.should include("article")
    end

    it "should contain 'action campaign' for all non-static pages with asks" do
      page_with_ask = create(:page_with_parent)
      content_module = create(:petition_module)
      page_with_ask.content_modules << content_module

      helper.instance_variable_set(:@page, page_with_ask)
      helper.body_class.should include("action campaign")
    end

    it 'should contain action for all static pages that has ask' do
      static_page_with_ask = create(:page, page_sequence: create(:page_sequence))
      content_module = create(:petition_module)
      static_page_with_ask.content_modules << content_module
      helper.instance_variable_set(:@page, static_page_with_ask)
      helper.body_class.should include("action")

      static_page_without_ask = create(:page, page_sequence: create(:page_sequence))
      helper.instance_variable_set(:@page, static_page_without_ask)
      helper.body_class.should_not include("action")
    end
  end

  describe "#body_id" do
    it "should return home for the home page" do
      helper.stub(:controller).and_return(HomeController.new)
      helper.body_id.should == "home"
    end

    it "should return home for the home page" do
      helper.stub(:controller).and_return(HomeController.new)
      helper.body_id.should == "home"
    end

    it "should return nil for pages without asks" do
      page_without_ask = create(:page_with_parent)

      helper.instance_variable_set(:@page, page_without_ask)
      helper.body_id.should == nil
    end

    it "should return appropriate id for different asks" do
      {:email_mp_module => 'email', :email_targets_module => 'email',
       :petition_module => 'petition', :call_mp_module => 'call',
       :donation_module => 'donation', :target_list_module => 'email',
       :tell_a_friend_ask_module => 'petition'
      }.each do |content_module, expected_id|
        page_with_ask = create(:page_with_parent)
        ask_module = create(content_module)
        page_with_ask.content_modules = [ask_module]

        helper.instance_variable_set(:@page, page_with_ask)
        helper.body_id.should == expected_id
      end
    end
  end

  describe '#form_errors' do
    context 'admin view form errors' do
      it 'should render admin_form_errors' do
        subject = Object.any_instance
        helper.stub(:params).and_return({:controller => 'admin/'})
        helper.should_receive(:render).with({:partial => 'common/admin_form_errors', :locals => {:subject => subject}})
        helper.form_errors(subject)
      end
    end

    context 'public view form errors' do
      it 'should render form_errors' do
        subject = Object.any_instance
        helper.stub(:params).and_return({:controller => ''})
        helper.should_receive(:render).with({:partial => 'common/form_errors', :locals => {:subject => subject}})
        helper.form_errors(subject)
      end
    end

    context 'form errors' do
      it 'should not contain field name if caret is the first character of the error message' do
        message = helper.humanized_error_message_for_field(:field_a, '^The error message')
        message.should == 'The error message'
      end

      it 'should not contain field name if field name is :base' do
        message = helper.humanized_error_message_for_field(:base, '^The error message')
        message.should == 'The error message'
      end

      it 'should contain the field in humanised form with the message if no caret in message param' do
        message = helper.humanized_error_message_for_field('field_a', 'the error message')
        message.should == 'Field a the error message'
      end

    
      context "#all_error_messages_for_field" do
        it "should show one message" do
          message = helper.all_error_messages_for_field(:field_a, ['cannot be blank'])
          message.should == 'Field a cannot be blank'
        end

        it "should handle caret" do
          message = helper.all_error_messages_for_field(:field_a, ['^The error message'])
          message.should == 'The error message'
        end

        it "should combine multiple errors" do
          message = helper.all_error_messages_for_field(:field_a, ['^The error message', 'cannot be blank'])
          message.should == 'The error message and Field a cannot be blank'
        end
      end
    end
  end

end
