require 'spec_helper'

describe Events::CommentsController do
  include Devise::TestHelpers

  before :each do
    sign_in @user = create(:user, :is_admin => false)
    @mock_warden = double(Warden, :authenticate => @user, :authenticate! => @user, :authenticate? => true, :session => @user)
    request.env['warden'] = @mock_warden
    controller.stub(:current_user) { @user }
    @event = create(:event)
  end

  it "should create a comment for the given event" do
    event = create(:event)
    post :create, :event_id => event.friendly_id, :body => "Can u believe that?"

    response.should redirect_to(event_path(event.friendly_id))
    flash[:notice].should == "Your comment has been posted."
    event.reload
    event.root_comments.size.should eql 1
    event.root_comments[0].body.should eql "Can u believe that?"
  end

  it "should stay on the same page if the comment is invalid" do
    event = create(:event)
    post :create, :event_id => event.friendly_id

    response.should render_template("events/show")
    assigns(:event).should_not be_nil
    assigns(:comment).should_not be_nil
  end

  it "should reply to an existing comment for the given event" do
    event = create(:event)
    comment = Comment.build_from(event, @user.id, "Oh hai?!")
    comment.save!
    post :reply, :event_id => event.friendly_id, :id => comment.id, :body => "Your comment are belong to us!"

    response.should redirect_to(event_path(event.friendly_id))
    flash[:notice].should == "Your reply has been posted."
    comment.reload
    comment.children.size.should eql 1
    comment.children[0].body.should eql "Your comment are belong to us!"
  end
end
