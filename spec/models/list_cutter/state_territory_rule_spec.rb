require File.expand_path(File.dirname(__FILE__) + "../../../spec_helper")

describe ListCutter::StateTerritoryRule do
  #TODO - look at campaign_rule_spec as an example of how to write rule tests.
  #This is not a good example as it compares the code to itself, and should be rewritten
  it "should yield correct relation" do
    # relation = User.joins(:postcode).where(:postcodes => {:state => ['NSW','QLD']})
    relation = User.joins(:postcode).where("postcodes.state in (?)", ['NSW','TAS'])
    # relation = User.joins(:user_activity_events => {:page => :page_sequence}).where("page_sequences.campaign_id in (?) and activity = 'action_taken'", [1,2,3])
    rule = ListCutter::StateTerritoryRule.new(:states_territories => ['NSW','TAS'])
    rule.to_relation.to_sql.should == relation.to_sql
  end

  it "should negate relation" do
    # relation = User.joins(:postcode).where(:postcodes => {:state => ['NSW','QLD']}
    relation = User.joins(:postcode).where("postcodes.state not in (?)", ['QLD','TAS'])    
    rule = ListCutter::StateTerritoryRule.new(:not => true, :states_territories => ['QLD','TAS'])
    rule.to_relation.to_sql.should == relation.to_sql
  end

  it "should validate itself" do
    rule = ListCutter::StateTerritoryRule.new

    rule.valid?.should be false
    rule.errors.messages == {:states_territories=>["Please select one or more states/territories"]}
  end

  context "unspecified states or territories" do
    let!(:user_no_state) { create(:user, email: 'no_postcode@email.com') }

    let!(:vic_postcode) { create(:postcode, number: "3231", longitude: "144.107", latitude: "-38.4594")}
    let!(:user_with_state) { create(:user, email: 'vic_postcode@email.com', postcode_id: vic_postcode.id) }

    it "should not validate state list" do
      rule = ListCutter::StateTerritoryRule.new(:no_state => "1")
      rule.valid?.should be true
    end

    it "should validate if selecting states from a list" do
      rule = ListCutter::PostcodeWithinRule.new(:no_state => '1', :states_territories => ['QLD'])
      rule.valid?.should be false
    end

    it "returns all users with no postcode records without negate" do
      rule = ListCutter::StateTerritoryRule.new(:no_state => "1")
      rule.to_relation.all.should == [user_no_state]
    end

    it "returns all users with postcode records with negate" do
      rule = ListCutter::StateTerritoryRule.new(:not => true, :no_state => "1", :states_territories => ['QLD'])
      rule.to_relation.all.should == [user_with_state]
    end
  end

  context "#active" do
    it "with 'Unknown State and Territories' is checked" do
      rule = ListCutter::StateTerritoryRule.new(:no_state=> "1", :states_territories => [])
      rule.active?.should be true
    end

    it "State is selected" do
      rule = ListCutter::StateTerritoryRule.new(:no_state=> "0", :states_territories => ["NSW"])
      rule.active?.should be true
    end

    it "State is not selected and 'Unknown State and Territories' is not checked" do
      rule = ListCutter::StateTerritoryRule.new(:no_state=> "0", :states_territories => [])
      rule.active?.should be false
    end
  end
end
