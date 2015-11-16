require 'spec_helper'

require 'rake'
require 'ostruct'

describe 'importing polling booths' do

  describe '#PollingBoothImporter.import_booth' do
    let!(:federal_jurisidiction) {create(:federal_jurisdiction)}
    let!(:electorate) {create(:sydney_federal, jurisdiction: federal_jurisidiction)}
    let!(:eden_monaro) {create(:eden_monaro, jurisdiction: federal_jurisidiction)}
    let!(:postcode) {create(:postcode)}
      
    load "#{Rails.root}/lib/tasks/import_polling_booths.rake"
    
    context 'with geo coords' do
      it 'imports the row into the correct fields' do
        PollingBoothImporter.import_booth(row_with_geo_coords)
        PollingBooth.count.should == 1
        assert_row_with_geo_location_imported_correctly(PollingBooth.first)
      end

      it 'imports the row into the correct fields' do
        PollingBoothImporter.import_booth(row_where_div_name_contains_hyphen)
        PollingBooth.count.should == 1
        assert_row_with_hyphenated_name_and_geo_location_imported_correctly(PollingBooth.first)
      end

      it 'imports row and associates it with federal electorate' do
        create(:sydney_federal, jurisdiction: create(:nsw_jurisdiction))

        PollingBoothImporter.import_booth(row_with_geo_coords)
        assert_row_with_geo_location_imported_correctly(PollingBooth.first)
      end

      it 'handles long booth entrance fields' do
        PollingBoothImporter.import_booth(row_with_long_booth_entrance)
        PollingBooth.count.should == 1
        assert_row_with_long_booth_entrance_imported_correctly(PollingBooth.first)
      end
    end

    context 'without geo coords' do
      it 'looks up the coordinates and import the row' do
        Geocoder.stub(:search).and_return([OpenStruct.new(latitude: 0.123, longitude: 2.34)])
        PollingBoothImporter.import_booth(row_without_geo_coords)

        PollingBooth.count.should == 1

        polling_booth = PollingBooth.first
        polling_booth.electorate_id.should == electorate.id
        polling_booth.premises_name.should == "P J Ferry Reserve Hall"
        polling_booth.address.should == "Level 2\ncnr Bellevue Pde & Blakesley Rd\nSurry Hills Business Park"
        polling_booth.suburb.should == 'Carlton'
        polling_booth.longitude.to_f.should be_within(0.01).of(2.34)
        polling_booth.latitude.to_f.should be_within(0.001).of(0.123)
        polling_booth.booth_location.should == ""
        polling_booth.booth_gate.should == ""
        polling_booth.booth_entrance.should == "Blakesley Rd Bellevue Pde"
        polling_booth.wheelchair.should == "Assisted"
      end
    end  

    context 'abolition' do
      it 'does not import the row' do
        PollingBoothImporter.import_booth(abolition_row)
        PollingBooth.count.should == 0
      end

    end    
  end

  def assert_row_with_long_booth_entrance_imported_correctly(polling_booth)
    polling_booth.electorate_id.should == electorate.id
    polling_booth.premises_name.should == "P J Ferry Reserve Hall"
    polling_booth.address.should == "Level 2\ncnr Bellevue Pde & Blakesley Rd\nSurry Hills Business Park"
    polling_booth.suburb.should == 'Carlton'
    polling_booth.longitude.should be_within(0.0000001).of(151.1148974)
    polling_booth.latitude.should be_within(0.0000001).of(-33.9767897)
    polling_booth.booth_location.should == "A location"
    polling_booth.booth_gate.should == "A gate access"
    polling_booth.booth_entrance.should == "Blakesley Rd Bellevue Pde Blakesley Rd Bellevue Pde Blakesley Rd Bellevue Pde Blakesley Rd Bellevue Pde Blakesley Rd Bellevue Pde Blakesley Rd Bellevue Pde Blakesley Rd Bellevue Pde Blakesley Rd Bellevue Pde Blakesley Rd Bellevue Pde Blakesley Rd Bellevue"
    polling_booth.wheelchair.should == "Assisted"
  end

  def assert_row_with_geo_location_imported_correctly(polling_booth)
    polling_booth.electorate_id.should == electorate.id
    polling_booth.premises_name.should == "P J Ferry Reserve Hall"
    polling_booth.address.should == "Level 2\ncnr Bellevue Pde & Blakesley Rd\nSurry Hills Business Park"
    polling_booth.suburb.should == 'Carlton'
    polling_booth.longitude.should be_within(0.0000001).of(151.1148974)
    polling_booth.latitude.should be_within(0.0000001).of(-33.9767897)
    polling_booth.booth_location.should == "A location"
    polling_booth.booth_gate.should == "A gate access"
    polling_booth.booth_entrance.should == "Blakesley Rd Bellevue Pde"
    polling_booth.wheelchair.should == "Assisted"
  end

  def assert_row_with_hyphenated_name_and_geo_location_imported_correctly(polling_booth)
    polling_booth.electorate_id.should == eden_monaro.id
    polling_booth.premises_name.should == "P J Ferry Reserve Hall"
    polling_booth.address.should == "Level 2\ncnr Bellevue Pde & Blakesley Rd\nSurry Hills Business Park"
    polling_booth.suburb.should == 'Carlton'
    polling_booth.longitude.should be_within(0.0000001).of(151.1148974)
    polling_booth.latitude.should be_within(0.0000001).of(-33.9767897)
    polling_booth.booth_location.should == "A location"
    polling_booth.booth_gate.should == "A gate access"
    polling_booth.booth_entrance.should == "Blakesley Rd Bellevue Pde"
    polling_booth.wheelchair.should == "Assisted"
  end
    
  def row_with_long_booth_entrance
    {
              "StateCo" => "2",
              "StateAb" => "NSW",
              "DivName" => "Sydney Federal",
                "DivId" => "103",
                "DivCo" => "1",
               "PPName" => "Allawah",
               "Status" => "Current",
         "PremisesName" => "P J Ferry Reserve Hall",
             "Address1" => "Level 2",
             "Address2" => "cnr Bellevue Pde & Blakesley Rd",
             "Address3" => "Surry Hills Business Park",
             "Locality" => "CARLTON",
          "AddrStateAb" => "NSW",
             "Postcode" => "#{postcode.number}",
                 "PPId" => "31",
     "AdvBoothLocation" => "A location",
        "AdvGateAccess" => "A gate access",
        "EntrancesDesc" => "Blakesley Rd Bellevue Pde Blakesley Rd Bellevue Pde Blakesley Rd Bellevue Pde Blakesley Rd Bellevue Pde Blakesley Rd Bellevue Pde Blakesley Rd Bellevue Pde Blakesley Rd Bellevue Pde Blakesley Rd Bellevue Pde Blakesley Rd Bellevue Pde Blakesley Rd Bellevue Pde Blakesley Rd Bellevue Pde Blakesley Rd Bellevue Pde Blakesley Rd Bellevue Pde Blakesley Rd Bellevue Pde Blakesley Rd Bellevue Pde Blakesley Rd Bellevue Pde Blakesley Rd Bellevue Pde Blakesley Rd Bellevue Pde",
                  "Lat" => "-33.9767897",
                 "Long" => "151.1148974",
                  "CCD" => "1361509",
     "WheelchairAccess" => "Assisted",
           "OrdVoteEst" => "1595",
           "DecVoteEst" => "160",
      "NoOrdIssuingOff" => "4",
    "NoOfDecIssuingOff" => "2"
    }
  end

  def row_with_geo_coords
    {
              "StateCo" => "2",
              "StateAb" => "NSW",
              "DivName" => "Sydney Federal",
                "DivId" => "103",
                "DivCo" => "1",
               "PPName" => "Allawah",
               "Status" => "Current",
         "PremisesName" => "P J Ferry Reserve Hall",
             "Address1" => "Level 2",
             "Address2" => "cnr Bellevue Pde & Blakesley Rd",
             "Address3" => "Surry Hills Business Park",
             "Locality" => "CARLTON",
          "AddrStateAb" => "NSW",
             "Postcode" => "#{postcode.number}",
                 "PPId" => "31",
     "AdvBoothLocation" => "A location",
        "AdvGateAccess" => "A gate access",
        "EntrancesDesc" => "Blakesley Rd Bellevue Pde",
                  "Lat" => "-33.9767897",
                 "Long" => "151.1148974",
                  "CCD" => "1361509",
     "WheelchairAccess" => "Assisted",
           "OrdVoteEst" => "1595",
           "DecVoteEst" => "160",
      "NoOrdIssuingOff" => "4",
    "NoOfDecIssuingOff" => "2"
    }
  end

  def row_without_geo_coords
    {
              "StateCo" => "2",
              "StateAb" => "NSW",
              "DivName" => "Sydney Federal",
                "DivId" => "103",
                "DivCo" => "1",
               "PPName" => "Allawah",
               "Status" => "Current",
         "PremisesName" => "P J Ferry Reserve Hall",
             "Address1" => "Level 2",
             "Address2" => "cnr Bellevue Pde & Blakesley Rd",
             "Address3" => "Surry Hills Business Park",
             "Locality" => "CARLTON",
          "AddrStateAb" => "NSW",
             "Postcode" => "#{postcode.number}",
                 "PPId" => "31",
     "AdvBoothLocation" => "",
        "AdvGateAccess" => "",
        "EntrancesDesc" => "Blakesley Rd Bellevue Pde",
                  "Lat" => "",
                 "Long" => "",
                  "CCD" => "1361509",
     "WheelchairAccess" => "Assisted",
           "OrdVoteEst" => "1595",
           "DecVoteEst" => "160",
      "NoOrdIssuingOff" => "4",
    "NoOfDecIssuingOff" => "2"
    }
  end

  def row_where_div_name_contains_hyphen
    {
              "StateCo" => "2",
              "StateAb" => "NSW",
              "DivName" => "Eden-Monaro",
                "DivId" => "103",
                "DivCo" => "1",
               "PPName" => "Allawah",
               "Status" => "Current",
         "PremisesName" => "P J Ferry Reserve Hall",
             "Address1" => "Level 2",
             "Address2" => "cnr Bellevue Pde & Blakesley Rd",
             "Address3" => "Surry Hills Business Park",
             "Locality" => "CARLTON",
          "AddrStateAb" => "NSW",
             "Postcode" => "#{postcode.number}",
                 "PPId" => "31",
     "AdvBoothLocation" => "A location",
        "AdvGateAccess" => "A gate access",
        "EntrancesDesc" => "Blakesley Rd Bellevue Pde",
                  "Lat" => "-33.9767897",
                 "Long" => "151.1148974",
                  "CCD" => "1361509",
     "WheelchairAccess" => "Assisted",
           "OrdVoteEst" => "1595",
           "DecVoteEst" => "160",
      "NoOrdIssuingOff" => "4",
    "NoOfDecIssuingOff" => "2"
    }
  end

  def abolition_row
    {
              "StateCo" => "2",
              "StateAb" => "NSW",
              "DivName" => "Sydney Federal",
                "DivId" => "103",
                "DivCo" => "1",
               "PPName" => "Allawah",
               "Status" => "Abolition",
         "PremisesName" => "P J Ferry Reserve Hall",
             "Address1" => "cnr Bellevue Pde & Blakesley Rd",
             "Address2" => "",
             "Address3" => "",
             "Locality" => "CARLTON",
          "AddrStateAb" => "NSW",
             "Postcode" => "#{postcode.number}",
                 "PPId" => "31",
     "AdvBoothLocation" => "",
        "AdvGateAccess" => "",
        "EntrancesDesc" => "Blakesley Rd Bellevue Pde",
                  "Lat" => "-33.9767897",
                 "Long" => "151.1148974",
                  "CCD" => "1361509",
     "WheelchairAccess" => "Assisted",
           "OrdVoteEst" => "1595",
           "DecVoteEst" => "160",
      "NoOrdIssuingOff" => "4",
    "NoOfDecIssuingOff" => "2"
    }
  end
end
