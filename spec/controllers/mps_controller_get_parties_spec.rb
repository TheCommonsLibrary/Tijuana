require File.expand_path(File.dirname(__FILE__) + "../../spec_helper")

describe MpsController do
  before(:each) do
    @party1 = create(:party)
    @tea_party = Party.create!(:name => "tea party", :abbreviation => "TEA")

    @getup_jurisdiction = create(:getup_jurisdiction)
    @getup_jurisdiction.parties << [@tea_party, @party1]
    @getup_jurisdiction.save!

    @nsw_jurisdiction = create(:nsw_jurisdiction)

    @email_mp_module = create(:email_mp_module, :jurisdiction_code => @getup_jurisdiction.code)
    @electorate1 = create(:sydney_federal, :jurisdiction => @getup_jurisdiction)
    @electorate2 = create(:sydney_local, :jurisdiction => @nsw_jurisdiction)

    @sydney_federal_region = create(:sydney_federal_region, :jurisdiction => @getup_jurisdiction)

    @mp1 = create(:mp, :first_name => "Colonel", :last_name => "Bobson", :email => "rickybobby@numberone.com", :electorate => @electorate1, :party => @party1)
    @postcode1 = create(:postcode, :electorates => [@electorate1, @electorate2], :regions => [@sydney_federal_region])
  end

  describe "party option to get when the jurisdiction changes" do

    it "should get parties for a given jurisdiction" do
      get :party_options, {:jurisdiction => @getup_jurisdiction.code, :module_id => @email_mp_module.id}
      assigns(:target_parties).size.should eql 2
      response.should be_success
      response.content_type.to_s.should eql "application/json"
      parsed_json = ActiveSupport::JSON.decode(response.body)
      parsed_json["target_senate"].should be true
      parsed_json["html"].include? "Australian Faker Party"
      parsed_json["html"].include? "tea party"
    end

    it "should set target senate to false if upper house is not present" do
      @getup_jurisdiction.upper_house_present = false
      @getup_jurisdiction.save!
      get :party_options, {:jurisdiction => @getup_jurisdiction.code, :module_id => @email_mp_module.id}
      parsed_json = ActiveSupport::JSON.decode(response.body)
      parsed_json["target_senate"].should be false
    end

  end

end
