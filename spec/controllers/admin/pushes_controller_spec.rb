require File.expand_path(File.dirname(__FILE__) + "../../../spec_helper")

describe Admin::PushesController do
  before :each do
    @campaign = create(:campaign)
    @valid_params = {
      :name => "Ceci nes pas une push"
    }
    @push = Push.create!(@valid_params.merge(:campaign => @campaign))
    sign_in create(:admin_user)
  end

  describe "responding to POST create" do
    describe "with valid params" do
      it "should create a push and redirect to its push page" do      
        post :create, :campaign_id => @campaign.id, :push => @valid_params
        push = assigns(:push)
        push.should_not be_new_record
        response.should redirect_to(admin_push_path(push))
      end
    end

    describe "with invalid params" do
      it "should not save the push and re-render the form" do
        post :create, :campaign_id => @campaign.id, :push => nil
        push = assigns(:push)
        push.should be_new_record
        response.should render_template("pushes/new")
      end
    end
  end
  describe "responding to PUT update" do
    describe "with valid params" do
      it "should update an push and redirect to its push admin page" do
        put :update, :id => @push.id, :push => @valid_params.merge(:name => "Something Else")
        @push.reload
        @push.name.should == "Something Else"
        response.should redirect_to(admin_push_path(@push))
      end
    end

    describe "with invalid params" do
      it "should not save the push and re-render the form" do
        put :update, {:id => @push.id, :push => {:name => ""}}
        response.should render_template("pushes/edit")
      end
    end
  end

  describe "responding to DELETE destroy" do
    it "should delete the push and redirect to campaign admin page" do
      delete :destroy, :id => @push.id
      @push.reload
      @push.should be_deleted
      response.should redirect_to(admin_campaign_path(@push.campaign))
    end
  end

  describe "responding to GET email_stats_report" do
    without_transactional_fixtures do
      it "should render a stats table for all emails within the push" do
        email = create(:email)
        get :email_stats_report, :id => email.blast.push.id
        csv = response.body.split("\n")
        csv[0].should == "Created,Blast,Email,Sent to,Opens,Opens % (opens / sent),Clicks,Clicks % (clicks / opens),Actions Taken,Actions Taken % (actions / sent),New Members,Unsubscribed,Unsubscribed % (unsubscribes / opens),Donations,Total $,Avg. $,Median $"
        csv[1].should match /[\d-]+,Dummy Blast Name,Dummy Email Name,0,0,0%,0,0%,0,0%,0,0,0%,0,\$0.00,\$0.00,\$0.00/
      end
    end
  end

  describe "responding to GET stats" do
    it "should render the email statistics" do
      email = create(:email)
      get :stats, :id => email.blast.push.id
      response.should render_template("pushes/_email_stats")
      response.status.should == 200
    end
  end

  describe "responding to POST notes" do
    it "should create a new note" do
      post :notes, :note => "SkyNet will take over!", :id => @push.id

      response.status.should == 200
      response.body.should eql "SkyNet will take over!"
      Note.first.value.should eql "SkyNet will take over!"
    end

    it "should return an application for invalid requests" do
      Note.any_instance.stub(:save) {false}
      post :notes, :note => nil, :id => @push.id

      response.body.should eql "There was a problem trying to edit your note. Please contact the administrator."
      response.status.should == 500
    end

    it "should replace line breaks for html br tags" do
      post :notes, :note => "SkyNet will take over!\nHasta la vista, baby!", :id => @push.id

      response.status.should == 200
      response.body.should eql "SkyNet will take over!<br/>Hasta la vista, baby!"
    end
  end

  describe 'deliver multiblast' do

    before :each do
      subject.stub(find_model: @push)
    end

    it 'should validate multiblast with email ids' do
      @push.should_receive(:multiblast_valid?).with([1,2])

      post :deliver_multiblast, id: @push.id, email_ids: "1,2"
    end

    it 'should send multiblast and redirect if it is valid' do
      @push.stub(multiblast_valid?: true)
      @push.should_receive(:send_multiblast!).with([1,3,2])

      post :deliver_multiblast, id: @push.id, email_ids: "1,3,2"

      response.should redirect_to admin_push_path(@push)
    end

    it 'should not send multiblast but render show if it is not valid' do
      @push.stub(multiblast_valid?: false)
      @push.should_not_receive(:send_multiblast!)

      post :deliver_multiblast, id: @push.id, email_ids: "some ids"

      assigns[:push].should == @push
      response.should render_template :show
    end
  end

  describe 'cancel multiblast' do

    before :each do
      subject.stub(find_model: @push)
    end

    it "releases push lock, cancels multiblast and redirects" do
      @push.should_receive(:cancel_multiblast!)
      @push.should_receive(:release_lock)

      post :cancel_multiblast, id: @push.id

      response.should redirect_to admin_push_path(@push)
    end

    it "return flash error if cannot cancel completed multiblast" do
      @push.should_receive(:cancel_multiblast!).and_return(nil)
      post :cancel_multiblast, id: @push.id
      response.should redirect_to admin_push_path(@push)
      flash[:error].should == "Multi blast cannot be cancelled"
    end

  end

  describe("/duplicate")do
    it "releases push lock, cancels multiblast and redirects" do
      post :duplicate, id: @push.id
      duplicated_push = Push.where('id <> ?', @push.id).last
      response.should redirect_to admin_push_path(duplicated_push)
    end
  end
end
