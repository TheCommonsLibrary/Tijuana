require File.expand_path(File.dirname(__FILE__) + "../../../spec_helper")

describe Admin::CampaignsController do
  include Devise::TestHelpers # to give your spec access to helpers

  before :each do
    @campaign = create(:campaign)
    sign_in create(:admin_user)
  end

  describe "responding to GET index" do
    it "should display campaigns" do
      get :index
      assigns(:campaigns).to_a.should == [@campaign]
    end

    it "should return search results appropriate to query" do
      get :index, :query => "dummy", :order => "created_at DESC"
      assigns(:campaigns).to_a.should == [@campaign]
    end
  end

  describe "#show" do
    let!(:page_sequence) {create(:page_sequence, campaign: @campaign)}
    let!(:push) {create(:push, campaign: @campaign)}
    let!(:get_together) {create(:get_together, campaign: @campaign)}

    it "should display page sequences, pushes and get togethers" do
      get :show, id: @campaign.id

      assigns(:sequences).to_a.should == [page_sequence]
      assigns(:pushes).to_a.should == [push]
      assigns(:get_togethers).to_a.should == [get_together]
    end
  end

  describe "responding to POST create" do
    describe "with valid params" do
      it "should create a campaign and redirect to its admin page" do
        post :create, :campaign => {:name => "Hello", accounts_key: 'Core'}
        @campaign = assigns(:campaign)
        @campaign.should_not be_new_record
        response.should redirect_to(admin_campaign_path(@campaign))
      end
    end

    describe "with invalid params" do
      it "should not save the campaign and re-render the form" do
        post :create, :campaign => nil
        @campaign = assigns(:campaign)
        @campaign.should be_new_record
        response.should render_template("campaigns/new")
      end
    end

    describe "responding to PUT update" do
      describe "with valid params" do
        it "should update a campaign and redirect to its admin page" do
          put :update, {:id => @campaign.id, :campaign => {:name => "Something Else"}}
          @campaign.reload
          @campaign.name.should == "Something Else"
          response.should redirect_to(admin_campaign_path(@campaign))
        end
      end

      describe "with invalid params" do
        it "should not save the campaign and re-render the form" do
          put :update, {:id => @campaign.id, :campaign => {:name => ""}}
          response.should render_template("campaigns/edit")
        end
      end
    end
  end

  describe "responding to DELETE destroy" do
    it "should delete the campaign redirect to campaign index" do
      delete :destroy, :id => @campaign.id
      @campaign.reload
      @campaign.should be_deleted
      response.should redirect_to(admin_campaigns_path)
    end
  end

  describe "responding to GET ask_stats_report" do
    it "should render a stats table for all asks within the campaign" do
      page = create(:page, :page_sequence => create(:page_sequence, :campaign => @campaign))
      page.content_modules << create(:donation_module)
      page.tag_list = "dummy_tag"
      page.save
      get :ask_stats_report, :id => @campaign.id
      csv = response.body.split("\n")
      csv[0].should == "Created,Page Sequence,Page,Tags,Ask Type,Actions Taken,New Members,Total $,Avg. $"
      csv[1].should match /[\d-]+,Dummy Page Sequence Name,Unnamed Page,dummy_tag,DonationModule,0,0,\$0.00,/
    end
  end

  describe "responding to GET show" do
    it "should make the necessary models available" do
      page = create(:page, :page_sequence => create(:page_sequence, :campaign => @campaign))
      page.content_modules << create(:donation_module)
      create(:push,  :campaign => @campaign)
      create(:get_together, :campaign => @campaign)

      get :show, :id => @campaign.id

      assigns(:campaign).should_not be_nil
      assigns(:sequences).should_not be_nil
      assigns(:pushes).should_not be_nil
      assigns(:get_togethers).should_not be_nil
    end
  end
end
