require File.expand_path(File.dirname(__FILE__) + "../../../spec_helper")

describe Admin::BlastsController do
  before :each do
    @push = create(:push)
    @valid_params = {
      :name => "Ceci nes pas une blast"
    }
    @blast = Blast.create!(@valid_params.merge(:push => @push))
    sign_in create(:admin_user)
  end

  describe "responding to POST create" do
    describe "with valid params" do
      it "should create a blast and redirect to its push page" do      
        post :create, :push_id => @push.id, :blast => @valid_params
        blast = assigns(:blast)
        blast.should_not be_new_record
        response.should redirect_to(admin_push_path(@push))
      end
    end

    describe "with invalid params" do
      it "should not save the blast and re-render the form" do
        post :create, :push_id => @push.id, :blast => nil
        blast = assigns(:blast)
        blast.should be_new_record
        response.should render_template("blasts/new")
      end
    end
  end
  describe "responding to PUT update" do
    describe "with valid params" do
      it "should update an blast and redirect to its blast admin page" do
        put :update, :id => @blast.id, :blast => @valid_params.merge(:name => "Something Else")
        @blast.reload
        @blast.name.should == "Something Else"
        response.should redirect_to(admin_push_path(@push))
      end
    end

    describe "with invalid params" do
      it "should not save the blast and re-render the form" do
        put :update, {:id => @blast.id, :blast => {:name => ""}}
        response.should render_template("blasts/edit")
      end
    end
  end
  
  describe "responding to DELETE destroy" do
    it "should delete the blast and redirect to push admin page" do
      delete :destroy, :id => @blast.id
      @blast.reload
      @blast.should be_deleted
      response.should redirect_to(admin_push_path(@push))
    end
  end

  describe "responding to POST delivery" do
    it "should blast all proofed emails" do
      Blast.stub(:find) { @blast }
      @blast.should_receive(:send_all_proofed_emails!)

      post :deliver, :id => @blast.id, :email_id => "all"

      response.should redirect_to(admin_push_path(@blast.push))
    end

    it "should blast all proofed emails up to a given limit" do
      Blast.stub(:find) { @blast }
      @blast.should_receive(:send_all_proofed_emails!).with(500)

      post :deliver, :id => @blast.id, :email_id => "all", :limit => 500

      response.should redirect_to(admin_push_path(@blast.push))

    end

    it "should blast a given email" do
      Blast.stub(:find) { @blast }
      @blast.should_receive(:send_proofed_emails!).with(["1"], nil)

      post :deliver, :id => @blast.id, :email_id => "1"

      response.should redirect_to(admin_push_path(@blast.push))
    end

    it "should blast a given email up to a given limit" do
      Blast.stub(:find) { @blast }
      @blast.should_receive(:send_proofed_emails!).with(["1"], 500)

      post :deliver, :id => @blast.id, :email_id => "1", :limit => 500

      response.should redirect_to(admin_push_path(@blast.push))
    end

    it "should blast once only" do
      Blast.stub(:find) { @blast }
      @blast.should_receive(:send_all_proofed_emails!).once

      10.times {post :deliver, :id => @blast.id, :email_id => "all"}

      response.should redirect_to(admin_push_path(@blast.push))
    end
  end

  describe "responding to POST cancel" do
    it "should cancel jobs belonging to the given blast" do
      Blast.stub(:find) { @blast }
      @blast.stub(:in_cooling_off_period?).and_return(true)
      @blast.should_receive(:cancel)

      post :cancel, :id => @blast.id

      response.should redirect_to(admin_push_path(@blast.push))
      flash[:notice].should == "Delivery cancelled"
    end
    
    it "should not cancel job when cooling off period has finished" do
      Blast.stub(:find) { @blast }
      @blast.stub(:in_cooling_off_period?).and_return(false)
      @blast.should_not_receive(:cancel)

      post :cancel, :id => @blast.id

      response.should redirect_to(admin_push_path(@blast.push))
      flash[:error].should == "Unable to cancel blast"
    end
  end
end
