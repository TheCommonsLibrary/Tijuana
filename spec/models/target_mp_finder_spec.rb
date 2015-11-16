require File.dirname(__FILE__) + '/../spec_helper.rb'

describe TargetMpFinder do
  pending "specs that deal with multiple MPs shouldn't be needed, right?; see 'app/models/electorate.rb:12'"

  let :jurisdiction_to_ignore do create(:getup_nsw_jurisdiction) end
  let :party_to_ignore do create(:party, name: 'Ignored Party', abbreviation: 'IGNORE', jurisdiction: jurisdiction_to_ignore) end
  let :electorate_to_ignore do create(:electorate, jurisdiction: jurisdiction_to_ignore) end
  let :mp_to_ignore do create(:mp, party: party_to_ignore, electorate: electorate_to_ignore) end
  let :region_to_ignore do create(:region, jurisdiction: jurisdiction_to_ignore) end
  let :senator_to_ignore do create(:senator, party: party_to_ignore, region: region_to_ignore) end

  before :each do
    # make sure these are created - these are here to make sure that the presence of other data does not c
    mp_to_ignore
    senator_to_ignore
  end

  let :jurisdiction do create(:getup_jurisdiction) end

  let :targeted_party do create(:party, name: 'Targeted Party', abbreviation: 'TAP', jurisdiction: jurisdiction) end
  let :other_party do create(:party, name: 'Other Party', abbreviation: 'OP', jurisdiction: jurisdiction) end

  let :electorate do create(:electorate, jurisdiction: jurisdiction) end
  let :region do create(:region, jurisdiction: jurisdiction) end
  let :postcode do create(:postcode, number: '2000', regions: [region, region_to_ignore], electorates: [electorate, electorate_to_ignore]) end

  describe "find_targeted_representatives" do

    def self.mp_behaviour
      it "should not find MP if not targeted" do
        create(:mp, party: other_party, electorate: electorate)
        electorate.reload
        targets = @finder.find_targeted_representatives(postcode)
        targets.should == []
      end
      it "should not find MP if not targeted, even if postcode has another electorate in another jurisdiction" do
        other_jurisdiction = create(:federal_jurisdiction)
        other_jurisdiction_electorate = create(:electorate, jurisdiction: other_jurisdiction)
        postcode = create(:postcode, number: '2000', electorates: [electorate, other_jurisdiction_electorate])

        create(:mp, first_name: 'NotTargeted', party: other_party, electorate: electorate)

        other_jurisdiction_party = create(:party, name: 'Other Jurisdiction Party', abbreviation: 'OJP', jurisdiction: other_jurisdiction)
        create(:mp, first_name: 'OtherJurisdiction', party: other_jurisdiction_party, electorate: other_jurisdiction_electorate)

        electorate.reload
        targets = @finder.find_targeted_representatives(postcode)
        targets.should == []
      end
      xit "should find multiple MPs if targeted" do
        targeted_mp1 = create(:mp, party: targeted_party, electorate: electorate)
        targeted_mp2 = create(:mp, party: targeted_party, electorate: electorate)
        electorate.reload
        targets = @finder.find_targeted_representatives(postcode)
        targets.length.should == 2
        targets.should include targeted_mp1
        targets.should include targeted_mp2
      end
      it "should find multiple MPs if postcode has multiple electorates" do
        other_electorate = create(:electorate, jurisdiction: jurisdiction)
        postcode = create(:postcode, number: '2000', electorates: [electorate, other_electorate])
        targeted_mp1 = create(:mp, party: targeted_party, electorate: electorate)
        targeted_mp2 = create(:mp, party: targeted_party, electorate: other_electorate)

        electorate.reload
        other_electorate.reload

        targets = @finder.find_targeted_representatives(postcode)
        targets.length.should == 2
        targets.should include targeted_mp1
        targets.should include targeted_mp2
      end
      it "should find multiple MPs, including untargeted, if postcode has multiple electorates and any electorate only has untargeted MPs" do
        other_jurisdiction = create(:federal_jurisdiction)
        other_jurisdiction_electorate = create(:electorate, jurisdiction: other_jurisdiction)
        other_electorate = create(:electorate, jurisdiction: jurisdiction)
        postcode = create(:postcode, number: '2000', electorates: [electorate, other_electorate, other_jurisdiction_electorate])
        targeted_mp1 = create(:mp, party: targeted_party, electorate: electorate)
        untargeted_mp1 = create(:mp, party: other_party, electorate: electorate)
        untargeted_mp2a = create(:mp, party: other_party, electorate: other_electorate)
        untargeted_mp2b = create(:mp, party: other_party, electorate: other_electorate)

        other_jurisdiction_party = create(:party, name: 'Other Jurisdiction Party', abbreviation: 'OJP', jurisdiction: other_jurisdiction)
        untargeted_mp2_other_jurisdiction = create(:mp, party: other_jurisdiction_party, electorate: other_jurisdiction_electorate)

        electorate.reload
        other_electorate.reload

        targets = @finder.find_targeted_representatives(postcode)
        targets.should include targeted_mp1
        targets.should include untargeted_mp2a
        targets.should include untargeted_mp2b
        targets.should_not include untargeted_mp1
        targets.should_not include untargeted_mp2_other_jurisdiction
        targets.length.should == 3
      end
    end

    def self.without_senate_fallback_behaviour
      it "should not find Senator even if no MP is found" do
        create(:senator, party: targeted_party, region: region)
        targets = @finder.find_targeted_representatives(postcode)
        targets.length.should == 0
      end
    end

    def self.senate_fallback_behaviour
      it "should find Senators if targeted" do
        targeted_senator1 = create(:senator, party: targeted_party, region: region)
        targeted_senator2 = create(:senator, party: targeted_party, region: region)
        region.reload
        targets = @finder.find_targeted_representatives(postcode)
        targets.length.should == 2
        targets.should include targeted_senator1
        targets.should include targeted_senator2
      end
      it "should not find Senator if not targeted" do
        create(:senator, party: other_party, region: region)
        region.reload
        targets = @finder.find_targeted_representatives(postcode)
        targets.length.should == 0
      end
    end

    context "without Senator fallback" do
      before :each do
        @finder = TargetMpFinder.new([targeted_party.id], jurisdiction.code, false)
      end

      mp_behaviour
      without_senate_fallback_behaviour
    end

    context "with Senator fallback" do
      before :each do
        @finder = TargetMpFinder.new([targeted_party.id], jurisdiction.code, true)
      end

      mp_behaviour
      senate_fallback_behaviour
    end

  end

  describe "target_message" do

    def self.mp_behaviour
      it "single MP" do
        create(:mp, party: targeted_party, first_name: 'Firstname', last_name: 'Lastname', electorate: electorate)
        electorate.reload
        @finder.target_message(postcode).should == ""
      end
      xit "multiple MPs for single electorate" do
        create(:mp, party: targeted_party, electorate: electorate)
        create(:mp, party: targeted_party, electorate: electorate)
        electorate.reload
        @finder.target_message(postcode).should == "Please select your representative from the list below:"
      end
      it "multiple MPs for multiple electorates" do
        other_electorate = create(:electorate, jurisdiction: jurisdiction)
        postcode = create(:postcode, number: '2000', electorates: [electorate, other_electorate])
        create(:mp, party: targeted_party, electorate: electorate)
        create(:mp, party: targeted_party, electorate: other_electorate)

        electorate.reload
        other_electorate.reload

        @finder.target_message(postcode).should == "Your postcode crosses electorates. Please select your representative from the list below:"
      end
      it "untargeted postcode" do
        other_jurisdiction = create(:federal_jurisdiction)
        other_jurisdiction_electorate = create(:electorate, jurisdiction: other_jurisdiction)
        postcode = create(:postcode, number: '2000', electorates: [other_jurisdiction_electorate])
        @finder.target_message(postcode).should == "It appears this postcode does not belong to an electorate we are targeting. If this is an error please let us know at: help@getup.org.au"
      end
    end

    def self.without_senate_fallback_behaviour
      it "returns message for MP is not targeted" do
        create(:senator, party: targeted_party, region: region)
        create(:mp, party: other_party, first_name: 'Firstname', last_name: 'Lastname', electorate: electorate)
        @finder.target_message(postcode).should == "Sorry, Firstname Lastname does not represent one of the target parties of this campaign, but thanks for your support."
      end
    end

    def self.senate_fallback_behaviour
      it 'should return message for no fallback senators' do
        create(:senator, first_name: 'FirstSen', last_name: 'LastSen', party: other_party, region: region)
        create(:mp, first_name: 'FirstMp', last_name: 'LastMp', party: other_party, electorate: electorate)
        electorate.reload
        @finder.target_message(postcode).should == "FirstMp LastMp does not represent one of the target parties of this campaign, and neither are any of your senators, but thanks for your support."
      end
      it 'should return message for single fallback senator' do
        create(:senator, first_name: 'FirstSen', last_name: 'LastSen', party: targeted_party, region: region)
        create(:mp, first_name: 'FirstMp', last_name: 'LastMp', party: other_party, electorate: electorate)
        electorate.reload
        @finder.target_message(postcode).should == "FirstMp LastMp does not represent one of the target parties of this campaign."
      end
      xit 'should return message for single fallback senator if multiple MPs found' do
        create(:mp, party: other_party, electorate: electorate)
        create(:mp, party: other_party, electorate: electorate)
        create(:senator, first_name: 'FirstSen', last_name: 'LastSen', party: targeted_party, region: region)
        electorate.reload
        @finder.target_message(postcode).should == "Your representative does not represent one of the target parties of this campaign."
      end
      it 'should return message for single fallback senator if no MP found' do
        create(:senator, first_name: 'FirstSen', last_name: 'LastSen', party: targeted_party, region: region)
        electorate.reload
        @finder.target_message(postcode).should == "Your representative does not represent one of the target parties of this campaign."
      end
      it 'should return message for multiple fallback senators' do
        create(:senator, party: targeted_party, region: region)
        create(:senator, party: targeted_party, region: region)
        create(:mp, first_name: 'FirstMp', last_name: 'LastMp', party: other_party, electorate: electorate)
        electorate.reload
        @finder.target_message(postcode).should == "FirstMp LastMp does not represent one of the target parties of this campaign. Please select a Senator from the list below:"
      end
      it 'should return message for multiple fallback senators if no MP is found' do
        create(:senator, party: targeted_party, region: region)
        create(:senator, party: targeted_party, region: region)
        electorate.reload
        @finder.target_message(postcode).should == "Your representative does not represent one of the target parties of this campaign. Please select a Senator from the list below:"
      end
      xit 'should return message for multiple fallback senators if multiple MPs found' do
        create(:mp, party: other_party, electorate: electorate)
        create(:mp, party: other_party, electorate: electorate)
        create(:senator, party: targeted_party, region: region)
        create(:senator, party: targeted_party, region: region)
        electorate.reload
        @finder.target_message(postcode).should == "Your representative does not represent one of the target parties of this campaign. Please select a Senator from the list below:"
      end
    end

    context "without Senator fallback" do
      before :each do
        @finder = TargetMpFinder.new([targeted_party.id], jurisdiction.code, false)
      end

      mp_behaviour
      without_senate_fallback_behaviour
    end

    context "with Senator fallback" do
      before :each do
        @finder = TargetMpFinder.new([targeted_party.id], jurisdiction.code, true)
      end

      mp_behaviour
      senate_fallback_behaviour
    end
  end
end
