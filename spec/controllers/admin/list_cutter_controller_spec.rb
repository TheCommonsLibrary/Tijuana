require 'spec_helper'

describe Admin::ListCutterController do
  before :each do
    sign_in create(:admin_user)
  end

  describe "GET 'edit'" do
    it "should load an existing list object" do
      list = List.new
      list.save!

      get 'edit', :list_id => list.id

      assigns(:list).should_not be_nil
      assigns(:list).should == list
      response.should be_success
    end
  end

  describe "GET 'new'" do
    context "low volume feature enabled" do
      before(:each) do
        AppConstants.stub(:low_volume_enabled).and_return(true)
      end

      it "should create a new instance of the List object (and should not include low volume members by default)" do
        get 'new'
        assigns(:list).should_not be_nil
        assigns(:list).should_not be_include_low_volume_members
        response.should be_success
      end
    end

    it "should exclude quarantine by default" do
        get 'new'
        assigns(:list).should_not be_nil
        assigns(:list).rules.select {|r| r.class.code.match /quarantine/ }[0].should_not be_nil
    end

    it "should create a new instance and assign a blast id to it when given one" do
      blast = create(:blast)
      get 'new', :blast_id => blast.id

      list = assigns(:list)
      list.should_not be_nil
      list.blast.should == blast
      response.should be_success
    end

  end

  describe "POST 'count'" do
    it "should build a list mirroring the received params" do
      postcode = create(:postcode)
      response = post 'count', :include_low_volume_members => '1', :rules => {
        :country_rule => {:activate => "1", :country_iso => "AU"},
        :email_domain_rule => {:activate => "1", :domain => "@gmail.com"},
        :postcode_within_rule => {:activate => "1", :postcode_ids => [postcode.id], :within => 30},
      }

      list = assigns(:list)

      list.should_not be_nil
      assigns(:list).should be_include_low_volume_members
      list.rules.size.should == 4

      list.rules.find { |i| i.class == ListCutter::CountryRule}.country_iso.should == "AU"
      list.rules.find { |i| i.class == ListCutter::EmailDomainRule}.domain.should == "gmail.com"
      list.rules.find { |i| i.class == ListCutter::PostcodeWithinRule}.postcode_ids.should == [postcode.id.to_s]

      json = JSON.parse(response.body)
      json["intermediate_result_id"].should_not be_nil
      json["list_id"].should_not be_nil
    end

    context "low volume feature enabled" do
      before(:each) do
        AppConstants.stub(:low_volume_enabled).and_return(true)
      end

      it "should add rule to exclude low volume members" do
        post 'count', rules: {}
        assigns(:list).rules.select {|r| r.class.code.match /low_volume/ }[0].should_not be_nil
      end
    end

    context "low volume feature disabled" do
      before(:each) do
        AppConstants.stub(:low_volume_enabled).and_return(false)
      end

      it "should ignore exclusion of low volume members" do
        response = post 'count', rules: {}
        assigns(:list).rules.select {|r| r.class.code.match /low_volume/ }[0].should be_nil
      end
    end

    it "should load and update an existing list if a valid id if given" do
      list = List.create
      list.set_country_rule(:country_iso => "AU")
      list.save

      response = post 'count', :list_id => list.id.to_s, :include_quarantine_members => '1', :include_low_volume_members => '1', :rules => {
        :email_domain_rule => {:activate => "1", :domain => "@gmail.com"},
        :country_rule => {:activate => "0", :country_iso => "FR"}
      }

      existing_list = assigns(:list)
      existing_list.id.should == list.id
      existing_list.rules.size.should == 1
      existing_list.rules.first.domain.should == "gmail.com"
    end

    it "should associate a blast with a newly created list if one is given" do
      blast = create(:blast)
      response = post 'count', :blast_id => blast.id, :rules => {}

      new_list = assigns(:list)
      new_list.blast.should == blast
    end

    it "should remove empty values from rule params" do
      response = post 'count', :include_quarantine_members => '1', :include_low_volume_members => '1', :rules => {
        :campaign_rule => {:activate => "1", :campaigns => ["", "1", "2"]},
        :state_territory_rule => {:activate => "1", :states_territories => ["", "NSW", "QLD", "SA"]},
        :donor_rule => {:activate => "1", :frequencies => ["", "", "weekly", ""]},
      }

      list = assigns(:list)

      list.rules.first.campaigns.should == ["1", "2"]
      list.rules.second.states_territories.should == ["NSW", "QLD", "SA"]
      list.rules.last.frequencies.should == ["weekly"]
    end
  end

  describe "GET 'poll'" do
    it "should render the json results correnponding to the query execution" do
      result = create(:list_intermediate_result, :ready => false)
      response = get :poll, :result_id => result.id, :format => "json"

      json = JSON.parse(response.body)
      json["ready"].should == false
    end

    it "should render the json results corresponding to the query execution" do
      data = {size: 10, total_time: 5, sql: "SELECT me"}
      result = create(:list_intermediate_result, :ready => true, :data => data)
      response = get :poll, :result_id => result.id, :format => "json"

      json = JSON.parse(response.body)
      json["ready"].should be true
      json["size"].should == data[:size]
      json["total_time"].should == data[:total_time]
      json["sql"].should == data[:sql]
    end
  end

end
