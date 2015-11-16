require File.expand_path(File.dirname(__FILE__) + "../../spec_helper")

describe "Post Code" do

  before(:each) do
    @nsw_jurisdiction = create(:nsw_jurisdiction, :parties => [])
    @federal_jurisdiction = create(:federal_jurisdiction, :parties => [])
  end

  it "should get electorates based on jurisdiction" do
    sydney_local_electorate = create(:sydney_local, :jurisdiction => @nsw_jurisdiction)
    sydney_federal_electorate = create(:sydney_federal, :jurisdiction => @federal_jurisdiction)

    postcode_2000 = create(:postcode_of_tw_office, :electorates => [sydney_federal_electorate, sydney_local_electorate])

    postcode_2000.electorates_by_jurisdiction_code(@nsw_jurisdiction.code).should include sydney_local_electorate
    postcode_2000.electorates_by_jurisdiction_code(@nsw_jurisdiction.code).size.should eql 1

    postcode_2000.electorates_by_jurisdiction_code(@federal_jurisdiction.code).should include sydney_federal_electorate
    postcode_2000.electorates_by_jurisdiction_code(@federal_jurisdiction.code).size.should eql 1

  end

  it "should get regions based on jurisdiction" do
    sydney_local_region = create(:sydney_local_region, :jurisdiction => @nsw_jurisdiction)
    sydney_federal_region = create(:sydney_federal_region, :jurisdiction => @federal_jurisdiction)

    postcode_2000 = create(:postcode_of_tw_office, :regions => [sydney_federal_region, sydney_local_region])

    postcode_2000.regions_by_jurisdiction_code(@nsw_jurisdiction.code).should include sydney_local_region
    postcode_2000.regions_by_jurisdiction_code(@nsw_jurisdiction.code).size.should eql 1

    postcode_2000.regions_by_jurisdiction_code(@federal_jurisdiction.code).should include sydney_federal_region
    postcode_2000.regions_by_jurisdiction_code(@federal_jurisdiction.code).size.should eql 1

  end

  it 'has many mps through electorates' do
    electorate1 = create(:electorate, jurisdiction: @federal_jurisdiction)
    electorate2 = create(:electorate, jurisdiction: @federal_jurisdiction)
    postcode = create(:postcode, electorates: [electorate1, electorate2])

    mp1 = create(:mp, electorate: electorate1)
    mp2 = create(:mp, electorate: electorate2)

    postcode.mps.should include mp1
    postcode.mps.should include mp2
  end

  it 'has many senators through regions' do
    region1 = create(:region, jurisdiction: @federal_jurisdiction)
    region2 = create(:region, jurisdiction: @federal_jurisdiction)
    postcode = create(:postcode, regions: [region1, region2])

    senator1 = create(:senator, region: region1)
    senator2 = create(:senator, region: region2)

    postcode.senators.should include senator1
    postcode.senators.should include senator2
  end

  describe '#add_leading_zero_if_three_digits' do
    it 'should add a leading zero to 3 digit numbers' do
      Postcode.add_leading_zero_if_three_digits('800').should == '0800'
    end

    it 'should not add a leading zero to a 4 digit number' do
      Postcode.add_leading_zero_if_three_digits('2000').should == '2000'
    end
  end

  describe "#most_populous_electorate" do
    let!(:postcode) {create(:postcode)}

    before(:each) do
      low_electorate = create(:electorate, name: 'low electorate', jurisdiction: @federal_jurisdiction)
      high_electorate = create(:electorate, name: 'high electorate', jurisdiction: @federal_jurisdiction)
      ActiveRecord::Base.connection.execute("INSERT INTO electorates_postcodes (electorate_id, postcode_id, population) values (#{high_electorate.id}, #{postcode.id}, 4000)")
      ActiveRecord::Base.connection.execute("INSERT INTO electorates_postcodes (electorate_id, postcode_id, population) values (#{low_electorate.id}, #{postcode.id}, 1000)")
    end

    context "with electorates in different jurisdictions" do
      let!(:electorate_different_jurisdiction) {create(:electorate, jurisdiction: @nsw_jurisdiction, name: 'nsw electorate')}

      before(:each) do
        ActiveRecord::Base.connection.execute("INSERT INTO electorates_postcodes (electorate_id, postcode_id, population) values (#{electorate_different_jurisdiction.id}, #{postcode.id}, 1000)")
      end

      it "should find the most populous electorate within the specified jurisdiction" do
        postcode.most_populous_electorate_by_jurisdiction_id(Jurisdiction.find_by_code('NSW').id).name.should == 'nsw electorate' 
        postcode.most_populous_electorate_by_jurisdiction_id(Jurisdiction.find_by_code('FEDERAL').id).name.should == 'high electorate' 
      end
    end
  end
end
