require File.expand_path(File.dirname(__FILE__) + "../../../spec_helper")

describe Admin::EmailsController do

  before :each do
    @blast = create(:blast)
    @valid_params = {
      :name => "Hello",
      :from_address => "from@getup.org.au", 
      :reply_to_address => "reply@getup.org.au",  
      :subject => "This is the subject", 
      :body => "<p>This is the body</p>"
    }
    @email = Email.create!(@valid_params.merge(:blast => @blast))
    sign_in create(:admin_user)
  end

  describe "responding to POST create" do
    describe "with valid params" do
      it "should create an email and redirect to its push page" do      
        post :create, :blast_id => @blast.id, :email => @valid_params
        email = assigns(:email)
        email.should_not be_new_record
        response.should redirect_to(admin_push_path(@blast.push))
      end

      it "should dispatch a test email" do
        test_recipients = ["test1@example.com", "test2@example.com"]
        email = Email.new(@valid_params.merge(:blast => @blast))
        Email.stub(:new) {email}
        email.should_receive(:send_test!).with(test_recipients)
        
        post :create, :blast_id => @blast.id, :email => @valid_params, :test_recipients => test_recipients.join(','), :submit => 'Send Proof'
      end

    end

    describe "with invalid params" do
      before(:each) do
        @email_with_invalid_params = {
            :name => "",
            :from_address => "",
            :reply_to_address => "",
            :subject => "",
            :body => ""
        }
      end
      it "should not save the email and re-render the form" do
        post :create, :blast_id => @blast.id, :email => @email_with_invalid_params
        email = assigns(:email)
        email.should be_new_record
        response.should render_template("emails/new")
      end

      it "should not send the email if it hasn't been created" do
        post :create, :blast_id => @blast.id, :email => @email_with_invalid_params, :test_recipients => "me@me.com"
        email = assigns(:email)
        email.should be_new_record
        response.should render_template("emails/new")
      end
    end
  end
  
  describe "responding to PUT update" do
    describe "with valid params" do
      it "should update an email and redirect to its push admin page" do
        put :update, :id => @email.id, :email => @valid_params.merge(:name => "Something Else")
        @email.reload
        @email.name.should == "Something Else"
        response.should redirect_to(admin_push_path(@blast.push))
      end
    end

    it "should dispatch a test email" do
      test_recipients = ["test1@example.com", "test2@example.com"]
      Email.stub(:find) { @email }
      @email.should_receive(:send_test!).with(test_recipients)

      put :update, :id => @email.id, :email => @valid_params.merge(:name => "Something Else"), :test_recipients => test_recipients.join(','), :submit=>'Send Proof'
      flash[:notice].should =~ /Saved and Proof queued/
    end

    it "should show error if clicked send proof but no email address provided" do
      Email.stub(:find) { @email }
      @email.should_not_receive(:send_test!)

      put :update, :id => @email.id, :email => @valid_params.merge(:name => "Something Else"), :submit=>'Send Proof'
      flash[:error].should =~ /Saved but Proof NOT sent/
    end

    it "should clear test timestamp if updating email without sending a test" do
      Email.stub(:find) { @email }
      @email.should_receive(:clear_test_timestamp)

      put :update, :id => @email.id, :email => @valid_params.merge(:body => "Something Else")
    end

    describe "with invalid params" do
      it "should not save the email and re-render the form" do
        put :update, {:id => @email.id, :email => {:name => ""}}
        response.should render_template("edit")
        flash[:error].should =~ /have NOT BEEN SAVED/
        flash[:error].should =~ /Please fix the errors/
        flash[:notice].should be_nil
      end
    end

    it "should call HtmlValidator and LinksLiveValidator if Save & Valid button is clicked" do
      body = "<p>This is email body</p>"
      HtmlValidator.stub(:service_available?).and_return(false)
      LinksLiveValidator.any_instance.stub(:is_url_reachable?).and_return(false)
      
      HtmlValidator.should_receive(:validate_each).with(@email, :body, body) 
      LinksLiveValidator.should_receive(:validate_each).with(@email, :body, body)

      put :update, :submit => 'Save & Validate', :id => @email.id, :email => @valid_params.merge(:name => "Something Else", :body => "<p>This is email body</p>")
    end

    it "should not call HtmlValidator and LinksLiveValidator if Save email is clicked" do
      HtmlValidator.should_not_receive(:validate_each).with(@email, :body, "<p>This is email body</p>")
      LinksLiveValidator.should_not_receive(:validate_each).with(@email, :body, "<p>This is email body</p>")
      put :update, :submit => 'Save email', :id => @email.id, :email => @valid_params.merge(:name => "Something Else", :body => "<p>This is email body</p>")
    end
  end
  
  describe "responding to DELETE destroy" do
    it "should delete the email and redirect to push admin page" do
      delete :destroy, :id => @email.id
      @email.reload
      @email.should be_deleted
      response.should redirect_to(admin_push_path(@blast.push))
    end
  end
  
end
