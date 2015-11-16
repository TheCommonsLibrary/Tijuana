require File.expand_path(File.dirname(__FILE__) + "../../spec_helper")

describe ActivityController do
  describe "#show" do
    before(:each) do
      (ActivityController::EVENT_COUNT + 10).times do |i|
        create(:user_activity_event, :activity=>:action_taken, :public_stream_html => 'Good stuff')
        create(:user_activity_event, :activity=>:action_taken, :public_stream_html => '<span class="name">Warren</span> donated to <a href="/campaigns/climate-action-now/temporary-page-sequence-for-imported-recurring-donors/temporary-page-for-imported-recurring-donors">a cause</a>.')
        create(:user_activity_event, :activity=>'subscribed', :public_stream_html =>'Bad stuff')
        create(:user_activity_event, :activity=>:action_taken, :source => "cr_creator", :public_stream_html =>'A new Community Run campaign')
      end
    end

    xit "renders the most recent :action_taken events with valid urls" do
      last_action = UserActivityEvent.where(:activity => :action_taken).where("public_stream_html like '%Good stuff%'").order("created_at desc").first
      response = get :show, :format => "json"
      response.body.should_not include("a cause")
      response.body.should_not include("Bad")
      response.body.should include("Good")
      response.body.should_not include("A new Community Run campaign")
      json = JSON.parse(response.body)
      json.count.should == ActivityController::EVENT_COUNT
      json.first["id"].should == last_action.id
      json.first["html"].should == last_action.public_stream_html
      json.first["timestamp"].should == last_action.created_at.httpdate
    end
  end
end
