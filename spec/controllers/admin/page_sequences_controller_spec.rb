require File.expand_path(File.dirname(__FILE__) + "../../../spec_helper")

describe Admin::PageSequencesController do
  include Devise::TestHelpers # to give your spec access to helpers
  
  before :each do
    @campaign = create(:campaign)
    sign_in create(:admin_user)
  end
  
  describe "responding to POST create" do
    describe "with valid params" do
      it "should create a page sequence and redirect to its campaigns admin page" do      
        post :create, :campaign_id => @campaign.id, :page_sequence => {:name => "Hello", facebook_image: 'http://'}
        campaign = assigns(:campaign)
        page_sequence = assigns(:page_sequence)
        page_sequence.should_not be_new_record
        page_sequence.campaign.should == @campaign
        response.should redirect_to(admin_page_sequence_path(page_sequence))
      end
    end
    
    describe "with invalid params" do
      it "should not save the page sequence and re-render the form" do
        post :create, :campaign_id => @campaign.id, :page_sequence => {:name => "lo"}
        page_sequence = assigns(:page_sequence)
        page_sequence.should be_new_record
        response.should render_template("page_sequences/new")
      end
    end
  end
  
  describe "responding to PUT update" do
    before :each do
      @page_sequence = create(:page_sequence, :campaign => @campaign, :name => "Hello")
    end
    
    describe "with valid params" do
      it "should update a page sequence and redirect to its admin page" do 
        put :update, :campaign_id => @campaign.id, :id => @page_sequence.id, :page_sequence => {:name => "Hola"}
        @page_sequence.reload
        @page_sequence.name.should == "Hola"
        response.should redirect_to(admin_page_sequence_path(@page_sequence))
      end
    end
  
    describe "with invalid params" do
      it "should not save the page sequence and re-render the form" do
        put :update, :campaign_id => @campaign.id, :id => @page_sequence.id, :page_sequence => {:name => "lo"}
        @page_sequence.reload
        @page_sequence.name.should == "Hello"
        response.should render_template("page_sequences/edit")
      end
    end
  end
  
  describe "responding to PUT sort" do
    it "should reorder pages even if validation fails" do
      @page_sequence = create(:page_sequence, :campaign => @campaign, :name => "Hello")
      p1 = create(:page, :page_sequence => @page_sequence, :name => "sequence1")
      p2 = create(:page, :page_sequence => @page_sequence, :name => "sequence2")

      p1.position.should == 1
      p2.position.should == 2
      
      put :sort_pages, :id => @page_sequence.id, :page => [p2.id.to_s, p1.id.to_s]
      
      p1.reload.position.should == 2
      p2.reload.position.should == 1
    end
  end
end
