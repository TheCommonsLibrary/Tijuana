# encoding: utf-8

require File.expand_path(File.dirname(__FILE__) + "../../spec_helper")

def validated_get_together(attrs)
    get_together = create(:get_together)
    get_together.update_attributes attrs
    get_together.valid?
    get_together
end

describe GetTogether do

  describe "event_full_message" do
    it "should have a default" do
      create(:get_together).event_full_message.should == 'This event is full'
    end

    it "should be settable" do
      non_default_message = "This is a test only"
      create(:get_together, event_full_message: non_default_message).event_full_message.should == non_default_message
    end
  end

  describe "event_closed_message" do
    it "should have a default" do
      create(:get_together).event_closed_message.should == 'This event is in the past'
    end

    it "should be settable" do
      non_default_message = "This is a test only"
      create(:get_together, event_closed_message: non_default_message).event_closed_message.should == non_default_message
    end
  end

  describe "action_button_text" do
    it "should have a default" do
      create(:get_together).action_button_text.should == 'View'
    end

    it "should be settable" do
      non_default_message = "This is a test only"
      create(:get_together, action_button_text: non_default_message).action_button_text.should == non_default_message
    end
  end

  it "should have a default host_greeting_email upon initialisation" do
    GetTogether.new.host_greeting_email.should == GetTogetherEmailTemplates::THANK_YOU_FOR_HOSTING
  end

  it "should have a default attendee_greeting_email upon initialisation" do
    GetTogether.new.attendee_greeting_email.should == GetTogetherEmailTemplates::THANK_YOU_FOR_ATTENDING
  end

  it "should cascade delete to events" do
    event = create(:event, :name => "Mighty event", :date => Date.today, :time => 700, :host_notes => "notes",
                           :host => create(:user, :email => 'troll@troll.com'),
                           :get_together => create(:get_together, :name => "hooo", :description => "desc", :content_module=>create(:html_module, :content=>"the content")))
    get_together = event.get_together
    get_together.destroy

    expect { Event.find(event.id) }.to raise_error(ActiveRecord::RecordNotFound)
  end

  it "should inform whether this get together has a time restriction or not" do
    get_together = build(:get_together, :name => "hooo", :description => "desc")
    get_together.has_time_restriction?.should be true

    get_together = build(:get_together, :name => "hooo", :description => "desc", :from_time => nil, :to_time => nil)
    get_together.has_time_restriction?.should be false

  end

  it "should return whether it is in the future or not" do
    expired_get_together = build(:get_together, :name => "hooo", :description => "desc", :to_date => Date.today-2.days) 
    current_get_together = build(:get_together, :name => "hooo", :description => "desc", :to_date => Date.today) 
    
    expired_get_together.in_future?.should == false         
    current_get_together.in_future?.should == true

  end

  describe "defaults" do
    it "should have appropriate defaults" do
      get_together = GetTogether.new
      get_together.tweet_text.should == "Why don't you check out this?"
      get_together.email_subject.should == "Check out this GetUp! event"
      get_together.email_body.should == "Why don't you check out this?"
      get_together.facebook_image.should == "http://localhost/images/public/getup_logo.png"
      get_together.html_meta_description.should == "An independent movement to build a progressive Australia and bring participation back into our democracy."
    end
  end

  it 'substitutes normal quotes for smart quotes' do
    get_together = create(:get_together,
      host_greeting_email: '“smart” double and ‘smart’ single quotes',
      attendee_greeting_email: '“smart” double and ‘smart’ single quotes'
    )
    get_together.host_greeting_email.should == %Q{"smart" double and 'smart' single quotes}
    get_together.attendee_greeting_email.should == %Q{"smart" double and 'smart' single quotes}
  end

  describe "exclusion_radius" do
    it "is 90% of default search radius" do
      get_together = create(:get_together, search_radius: 100)
      get_together.exclusion_radius.should == 90
    end
  end

  describe "valid input" do
    describe "url" do
      it "should be valid when null" do
        subject.redirect_url = nil
        subject.should have(0).error_on(:redirect_url)
      end

      it "should be valid when empty string" do
        subject.redirect_url = ''
        subject.should have(0).error_on(:redirect_url)
      end

      it "should be valid when correct URL" do
        subject.redirect_url = "http://www.thoughtworks.com"
        subject.should have(0).error_on(:redirect_url)
      end

      it "should be invalid when incorrect URL" do
        subject.redirect_url = "dsafasdf"
        subject.should have(1).error_on(:redirect_url)
      end
    end
  end
end
