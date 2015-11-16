require File.dirname(__FILE__) + '/../spec_helper.rb'

describe TargetSenatorFinder do

  let :jurisdiction_to_ignore do create(:getup_nsw_jurisdiction) end
  let :party_to_ignore do create(:party, name: 'Ignored Party', abbreviation: 'IGNORE', jurisdiction: jurisdiction_to_ignore) end
  let :region_to_ignore do create(:region, jurisdiction: jurisdiction_to_ignore) end
  let :senator_to_ignore do create(:senator, party: party_to_ignore, region: region_to_ignore) end

  before :each do
    # make sure these are created
    senator_to_ignore
    @finder = TargetSenatorFinder.new([targeted_party.id], jurisdiction.code)
  end

  let :jurisdiction do create(:getup_jurisdiction) end

  let :targeted_party do create(:party, name: 'Targeted Party', abbreviation: 'TAP', jurisdiction: jurisdiction) end
  let :other_party do create(:party, name: 'Other Party', abbreviation: 'OP', jurisdiction: jurisdiction) end

  let :region do create(:region, jurisdiction: jurisdiction) end
  let :postcode do create(:postcode, number: '2000', regions: [region, region_to_ignore]) end


  describe "find_targeted_representatives" do

    it "should not find Senator if not targeted" do
      create(:senator, party: other_party, region: region)
      targets = @finder.find_targeted_representatives(postcode)
      targets.should == []
    end

    it "should not find senator if not targeted, even if postcode has another region in another jurisdiction" do
      other_jurisdiction = create(:federal_jurisdiction)
      other_jurisdiction_region = create(:region, jurisdiction: other_jurisdiction)
      postcode = create(:postcode, number: '2000', regions: [region, other_jurisdiction_region])

      create(:senator, first_name: 'NotTargeted', party: other_party, region: region)

      other_jurisdiction_party = create(:party, name: 'Other Jurisdiction Party', abbreviation: 'OJP', jurisdiction: other_jurisdiction)
      create(:senator, first_name: 'OtherJurisdiction', party: other_jurisdiction_party, region: other_jurisdiction_region)

      targets = @finder.find_targeted_representatives(postcode)
      targets.should == []
    end

    it "should find multiple senators if targeted" do
      targeted_senator1 = create(:senator, party: targeted_party, region: region)
      targeted_senator2 = create(:senator, party: targeted_party, region: region)
      targets = @finder.find_targeted_representatives(postcode)
      targets.should include targeted_senator1
      targets.should include targeted_senator2
      targets.length.should == 2
    end

    it "should find multiple senators if postcode has multiple regions" do
      other_region = create(:region, jurisdiction: jurisdiction)
      postcode = create(:postcode, number: '2000', regions: [region, other_region])
      targeted_senator1 = create(:senator, party: targeted_party, region: region)
      targeted_senator2 = create(:senator, party: targeted_party, region: other_region)
      targets = @finder.find_targeted_representatives(postcode)
      targets.should include targeted_senator1
      targets.should include targeted_senator2
      targets.length.should == 2
    end

    it "should find multiple senators, including untargeted, if postcode has multiple regions and any region only has untargeted senators" do
      other_jurisdiction = create(:federal_jurisdiction)
      other_jurisdiction_region = create(:region, jurisdiction: other_jurisdiction)
      other_region = create(:region, jurisdiction: jurisdiction)
      postcode = create(:postcode, number: '2000', regions: [region, other_region, other_jurisdiction_region])
      targeted_senator1 = create(:senator, party: targeted_party, region: region)
      untargeted_senator1 = create(:senator, party: other_party, region: region)
      untargeted_senator2a = create(:senator, party: other_party, region: other_region)
      untargeted_senator2b = create(:senator, party: other_party, region: other_region)

      other_jurisdiction_party = create(:party, name: 'Other Jurisdiction Party', abbreviation: 'OJP', jurisdiction: other_jurisdiction)
      untargeted_senator2_other_jurisdiction = create(:senator, party: other_jurisdiction_party, region: other_jurisdiction_region)

      targets = @finder.find_targeted_representatives(postcode)
      targets.should include targeted_senator1
      targets.should include untargeted_senator2a
      targets.should include untargeted_senator2b
      targets.should_not include untargeted_senator1
      targets.should_not include untargeted_senator2_other_jurisdiction
      targets.length.should == 3
    end

  end

  describe "target_message" do

    it "no targeted senator" do
      create(:senator, party: other_party, first_name: 'Firstname', last_name: 'Lastname', region: region)
      @finder.target_message(postcode).should == "Sorry, Firstname Lastname does not represent one of the target parties of this campaign, but thanks for your support."
    end
    it "no targeted senators" do
      create(:senator, party: other_party, region: region)
      create(:senator, party: other_party, region: region)
      @finder.target_message(postcode).should == "Sorry, your representative does not represent one of the target parties of this campaign, but thanks for your support."
    end
    it "single senator" do
      create(:senator, party: targeted_party, first_name: 'Firstname', last_name: 'Lastname', region: region)
      @finder.target_message(postcode).should == ""
    end
    it "multiple senators for single region" do
      create(:senator, party: targeted_party, region: region)
      create(:senator, party: targeted_party, region: region)
      @finder.target_message(postcode).should == "Please select a Senator from the list below:"
    end
    it "multiple senators for multiple regions" do
      other_region = create(:region, jurisdiction: jurisdiction)
      postcode = create(:postcode, number: '2000', regions: [region, other_region])
      create(:senator, party: targeted_party, region: region)
      create(:senator, party: targeted_party, region: other_region)
      @finder.target_message(postcode).should == "Your postcode crosses regions. Please select a Senator from the list below:"
    end
    it "untargeted postcode" do
      other_jurisdiction = create(:federal_jurisdiction)
      other_jurisdiction_region = create(:region, jurisdiction: other_jurisdiction)
      postcode = create(:postcode, number: '2000', regions: [other_jurisdiction_region])
      @finder.target_message(postcode).should == "It appears this postcode does not belong to a region we are targeting. If this is an error please let us know at: help@getup.org.au"
    end

  end

  describe "target_message_when_falling_back" do
    let :mp do build(:mp, first_name: 'MpFirst', last_name: 'MpLast') end
    let :senator1 do build(:senator, first_name: 'SenatorFirst', last_name: 'SenatorLast') end
    let :senator2 do build(:senator) end
    let :postcode do double('postcode',regions_by_jurisdiction_code: [build(:region)]) end


    it 'tells us our region is not targeted' do
      postcode = double('postcode')
      postcode.should_receive(:regions_by_jurisdiction_code).with(jurisdiction.code).and_return([])
      @finder.target_message_when_falling_back(postcode, [], mp).should == 'MpFirst MpLast does not represent one of the target parties of this campaign, and it appears that this postcode does not belong to a region we are targeting in the Senate. If this is an error please let us know at: help@getup.org.au'
    end

    it 'tells us there are no Senators' do
      @finder.target_message_when_falling_back(postcode, [], mp).should == 'MpFirst MpLast does not represent one of the target parties of this campaign, and neither are any of your Senators, but thanks for your support.'
    end

    it 'tells us to chose form a list of Senators' do
      @finder.target_message_when_falling_back(postcode, [senator1, senator2], mp).should == 'MpFirst MpLast does not represent one of the target parties of this campaign. Please select a Senator from the list below:'
    end

    it 'tells us that the MP is not targeted' do
      @finder.target_message_when_falling_back(postcode, [senator1], mp).should == 'MpFirst MpLast does not represent one of the target parties of this campaign.'
    end
  end

end
