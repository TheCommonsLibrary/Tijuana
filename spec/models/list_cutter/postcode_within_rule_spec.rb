require File.expand_path(File.dirname(__FILE__) + "../../../spec_helper")

describe ListCutter::PostcodeWithinRule do
  #TODO - look at campaign_rule_spec as an example of how to write rule tests.
  #This is not a good example as it compares the code to itself, and should be rewritten
  it "defaults to inactive" do
    rule = ListCutter::PostcodeWithinRule.new()
    rule.active?.should be false
  end

  context "specified postcode(s)" do
    it "should generate the correct relation" do
      postcode = create(:postcode_of_tw_office)
      relation = User.where(["users.postcode_id in (?)", postcode.id])

      rule = ListCutter::PostcodeWithinRule.new(:postcode_ids=>[postcode.id], :within=>1)
      rule.to_relation.to_sql.should == relation.to_sql
    end

    it "should negate the correct relation" do
      postcode = create(:postcode_of_tw_office)
      relation = User.where(["users.postcode_id not in (?)", postcode.id])

      rule = ListCutter::PostcodeWithinRule.new(:postcode_ids=>[postcode.id], :within=>1, :not => true)
      rule.to_relation.to_sql.should == relation.to_sql
    end

    it "should query for suburbs within 10km of the postcode 2000" do
      create(:brazilian_activity)
      create(:leo_activity)
      activity = create(:aussie_activity)
      postcode_id = activity.user.postcode_id

      postcodes = ListCutter::PostcodeWithinRule.new(:postcode_ids=>[postcode_id], :within=>10).to_relation.all
      postcodes.size.should == 1
    end

    it 'should query for suburbs within 10km of multiple postcodes' do
      user1 = create(:user, :postcode => create(:postcode_of_circular_quay))
      user2 = create(:user, :postcode => create(:postcode_of_edgewater))
      postcode_ids = [user1.postcode_id, user2.postcode_id]

      postcodes = ListCutter::PostcodeWithinRule.new(:postcode_ids => postcode_ids, :within => 10).to_relation.all
      postcodes.size.should == 2
    end

    it "should query for the postcode 2000" do
      create(:brazilian_activity)
      create(:leo_activity)
      activity = create(:aussie_activity)
      postcode_id = activity.user.postcode_id

      postcodes = ListCutter::PostcodeWithinRule.new(:postcode_ids=>[postcode_id], :within=>"").to_relation.all
      postcodes.size.should == 1
    end

    it 'should query for multiple postcodes' do
      activity1 = create(:brazilian_activity)
      activity2 = create(:aussie_activity)
      postcode_ids = [activity1.user.postcode_id, activity2.user.postcode_id]

      postcodes = ListCutter::PostcodeWithinRule.new(:postcode_ids => postcode_ids, :within => '').to_relation.all
      postcodes.size.should == 2
    end

    it "should return self if distance is zero" do
      create(:brazilian_activity)
      create(:leo_activity)
      aussie_activity = create(:aussie_activity)
      postcode_id = aussie_activity.user.postcode_id

      postcodes = ListCutter::PostcodeWithinRule.new(:postcode_ids=>[postcode_id], :within=>"").to_relation.all
      postcodes.size.should == 1
      postcodes[0].postcode_id.should == aussie_activity.user.postcode_id
    end

    it "should validate postcode" do
      rule = ListCutter::PostcodeWithinRule.new

      rule.valid?.should be false
      rule.errors.messages == {:postcode_ids=>["Please provide a postcode"]}
    end

    it "should validate numericality of distance" do
      rule = ListCutter::PostcodeWithinRule.new(:postcode_ids => [1], :within => "INVALID DISTANCE")

      rule.valid?.should be false
      rule.errors.messages == {:within=>["Distance within has to be a number"]}
    end
  end

  context "unspecified postcode" do
    let!(:user_no_postcode) { create(:user, :email => 'user_no_postcode@email.com')}

    let!(:vic_postcode) { create(:postcode, number: "3231", longitude: "144.107", latitude: "-38.4594")}
    let!(:user_in_vic) { create(:user, :email => 'user_in_vic@email.com', :postcode_id => vic_postcode.id) }

    it "should not validate postcode list" do
      rule = ListCutter::PostcodeWithinRule.new(:no_postcode => '1')
      rule.valid?.should be true
    end

    it "should validate if selecting postcodes from a list" do
      rule = ListCutter::PostcodeWithinRule.new(:no_postcode => '1', :postcode_ids => [vic_postcode.id])
      rule.valid?.should be false
    end

    it "should return all users with no postcode records without negate" do
      rule = ListCutter::PostcodeWithinRule.new(:no_postcode => '1')
      rule.to_relation.all.should == [user_no_postcode]
    end

    it "should return all users with postcode records with negate" do
      rule = ListCutter::PostcodeWithinRule.new(:no_postcode => '1', :not => true)
      rule.to_relation.all.should == [user_in_vic]
    end
  end

  context "#active" do
    let!(:vic_postcode) { create(:postcode, number: "3231", longitude: "144.107", latitude: "-38.4594")}
    it "with 'Unknown Postcode' is checked" do
      rule = ListCutter::PostcodeWithinRule.new(:no_postcode=> "1", :postcode_ids => [])
      rule.active?.should be true
    end

    it "Poscode is selected" do
      rule = ListCutter::PostcodeWithinRule.new(:no_postcode=> "0", :postcode_ids => [vic_postcode.id])
      rule.active?.should be true
    end

    it "Postcode is not selected and 'Unknown Postcode' is not checked" do
      rule = ListCutter::PostcodeWithinRule.new(:no_postcode=> "0", :postcode_ids => [])
      rule.active?.should be false
    end
  end
end
