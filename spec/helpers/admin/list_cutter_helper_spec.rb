require 'spec_helper'

describe Admin::ListCutterHelper do
  describe "#get_rule" do
    it "should retrieve the rule specified by the given symbol" do
      list = List.new
      list.set_action_taken_rule(:page_ids => [1])

      action_taken = helper.get_rule(list, ListCutter::ActionTakenRule)
      action_taken.should be_instance_of ListCutter::ActionTakenRule
      action_taken.page_ids.should == [1]
    end

    it "should return a new rule instance if none found" do
      list = List.new

      helper.get_rule(list, ListCutter::ActionTakenRule).should be_instance_of ListCutter::ActionTakenRule
      helper.get_rule(list, ListCutter::EmailDomainRule).should be_instance_of ListCutter::EmailDomainRule
    end
  end

  describe "#electorate_select_options" do
    it "should return a hash of select options to be used in the view" do
      electorate = create(:electorate, name: 'Moore')
      sydney_electorate = create(:electorate, name: 'Sydney')

      helper.electorate_select_options.should_not be_nil
      helper.electorate_select_options["Moore"].should == electorate.id
      helper.electorate_select_options["Sydney"].should == sydney_electorate.id
    end
  end

  describe "#federal_electorates" do
    it "should return list of federal electorates" do
      federal_jurisdiction = create(:federal_jurisdiction)
      nsw_jurisdiction = create(:nsw_jurisdiction)
      federal_electorates = create(:sydney_federal, jurisdiction: federal_jurisdiction)
      nsw_electorates = create(:sydney_electorate, jurisdiction: nsw_jurisdiction)

      electorates = helper.federal_electorates

      electorates.count.should == 1
      electorates.first.should == ["Sydney Federal", federal_electorates.id]
    end
  end

  describe '#postcodes' do
    it 'should return a list of postcodes' do
      postcode = create(:postcode)
      postcodes = helper.postcode_options

      postcodes.count.should == 1
      postcodes.first.should == [ postcode.number, postcode.id ]
    end
  end
end
