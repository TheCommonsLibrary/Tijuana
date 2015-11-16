require File.expand_path(File.dirname(__FILE__) + "../../../spec_helper")

describe ListCutter::ElectorateRule do
  context "#to_relation" do
    before (:each) do
      @sydney_postcode = create(:postcode_of_circular_quay)
      @hobart_postcode = create(:postcode_of_hobart)
      @sydney_member = create(:user, :postcode => @sydney_postcode, :email => 'sydney@member.com')
      @hobart_member = create(:user, :postcode => @hobart_postcode, :email => 'hobart@member.com')

      federal_jurisdiction = create(:federal_jurisdiction)
      @sydney_electorate = create(:sydney_federal, jurisdiction: federal_jurisdiction)
      @denison_federal_electorate = create(:electorate, name: "Denison Federal", jurisdiction: federal_jurisdiction)

      @sydney_postcode.electorates << @sydney_electorate
      @hobart_postcode.electorates << @denison_federal_electorate
    end

    context "without 'send_to_no_postcode'" do
      it "should include members from specified electorate" do
        found_members = ListCutter::ElectorateRule.new(:electorate_ids => [@sydney_electorate.id]).to_relation.all
        found_members.should eql([@sydney_member])
      end

      it "should exclude members from specified electorate" do
        tas_jurisdiction = create(:tas_jurisdiction)
        denison_state_electorate = create(:electorate, name: "Denison State", jurisdiction: tas_jurisdiction)
        @hobart_postcode.electorates << denison_state_electorate
        found_members = ListCutter::ElectorateRule.new(:electorate_ids => [@denison_federal_electorate.id], :not => true, :send_to_no_postcode => '0').to_relation.all
        found_members.should eql([@sydney_member])
      end
    end

    context "with 'send_to_no_postcode'" do
      let!(:no_postcode_user) { create(:user, postcode_id: nil, email: 'i-got-no@postcode.com') }
      it "should include members from specified electorates and those without postcodes" do
        found_members = ListCutter::ElectorateRule.new(:electorate_ids => [@sydney_electorate.id], :send_to_no_postcode => '1').to_relation.all
        found_members.should include(@sydney_member)
        found_members.should include(no_postcode_user)
        found_members.should_not include(@hobart_member)
      end

      it "should exclude members from specified electorates and include those with no postcodes" do
        found_members = ListCutter::ElectorateRule.new(:electorate_ids => [@sydney_electorate.id], :not => true, :send_to_no_postcode => '1').to_relation.all
        found_members.should_not include(@sydney_member)
        found_members.should include(no_postcode_user)
        found_members.should include(@hobart_member)
      end
    end

  end

  describe "Validates electorate_ids" do
    it "should validate electorate id when given valid value" do
      rule = ListCutter::ElectorateRule.new(:electorate_ids => [100])
      rule.valid?.should be true
      rule.errors.messages.should be_empty
    end

    it "should be invalid when electorate_ids is empty" do
      rule = ListCutter::ElectorateRule.new(:electorate_ids => [])
      rule.valid?.should be false
      rule.errors.messages.should == {:electorate_ids=>["Please specify the electorates"]}
    end
  end
end

