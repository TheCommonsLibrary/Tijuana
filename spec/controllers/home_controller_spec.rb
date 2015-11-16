require File.expand_path(File.dirname(__FILE__) + "../../spec_helper")

describe HomeController do
  describe "allowing users to subscribe" do
    it "shows a static welcome page on success" do
      response = post :subscribe, :user => {:email => "someone@awesome.com"}
      response.should redirect_to("/membership/welcome-to-getup")
      User.find_by_email("someone@awesome.com").should_not be_nil
    end

    it "should consider the user's registration as a success if a duplicate email exception is raised" do
      post :subscribe, :user => {:email => "someone@awesome.com"}
      e = ActiveRecord::RecordNotUnique.new('blah','potato')
      User.any_instance.stub(:save).and_raise(e)
      response = post :subscribe, :user => {:email => "someone@awesome.com"}
      response.should redirect_to("/membership/welcome-to-getup")
      User.find_by_email("someone@awesome.com").should_not be_nil
    end

    it "ignores all parameters except email" do
      response = post :subscribe, :user => {:email => "someone2@awesome.com", :is_admin=>true, :first_name=>'fred'}
      user = User.find_by_email("someone2@awesome.com")
      user.is_admin.should == false
      user.first_name.should be_nil
    end

    it "redirects to root page if email is not valid" do
      response = post :subscribe, :user => {:email => "not.valid"}
      response.should redirect_to("/")
    end

    it "sends welcome email" do
      UserMailer.should_receive(:welcome_to_getup).with(an_instance_of(User))
      post :subscribe, :user => {:email => "someone@awesome.com"}
    end

    it 'should set the source as homepage' do
      post :subscribe, :user => {:email => "someone@awesome.com"}
      user = User.find_by_email('someone@awesome.com')
      uae = UserActivityEvent.find_by_user_id(user.id)
      uae.activity.should == UserActivityEvent::Activity::SUBSCRIBED
      uae.source.should == 'homepage'
    end

  end

  describe "robots.txt" do
    before{ get :robots, format: 'text' }
    specify{ expect(response).to be_success }
  end
end
