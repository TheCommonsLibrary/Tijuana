require File.dirname(__FILE__) + '/../spec_helper.rb'

describe AddressService, :vcr, speed: 'slow' do
  context 'query address' do

    it 'should return expected json result for address' do
      address = '104 commonwealth'
      result = ADDRESS_SERVICE.lookup_address_using_partial_address(address)
      result.should include address
    end

    it 'should return expected json result for id' do
      id = 'fbfab5f7-e660-4642-891b-887e89b0ff49--1'
      result = ADDRESS_SERVICE.lookup_address_using_search_result_id(id)
      result.should include id
    end
  end
end

describe AddressService do

  describe '#populate_user_address_from_search_result_id!' do
    before :each do
      @address_service = AddressService.new('http://uri', 'username', 'password')
      @response = JSON.parse(JSON_RESPONSE_SUCCESS)
      @search_result_id = 'fbfab5f7-e660-4642-891b-887e89b0ff49--1'
      @address_service.stub(:full_address_lookup).with(@search_result_id).and_return(@response)
    end

    context 'response indicates failure' do
      before :each do
        postcode = create(:postcode, :number => '2000')
        @user_from_2000 = create(:user, :street_address => '51 Pitt St', :suburb => 'Sydney', :postcode => postcode)
      end

      it 'should raise an exception if response status is not OK' do
        @response['status'] = nil
        expect{@address_service.populate_user_address_from_search_result_id!(@user_from_2000, @search_result_id)}.to raise_error(Exception)
      end

      it 'should raise an exception if dpid is nil' do
        @response['result']['dpid'] = nil
        expect{@address_service.populate_user_address_from_search_result_id!(@user_from_2000, @search_result_id)}.to raise_error(Exception)
      end

      it 'should raise an exception if there was an error in the request' do
        @address_service.stub(:full_address_lookup).with(@search_result_id).and_return(nil)
        expect{@address_service.populate_user_address_from_search_result_id!(@user_from_2000, @search_result_id)}.to raise_error(Exception)
      end

      it 'should raise an exception if the generated search result id expires' do
        response = JSON.parse(JSON_RESPONSE_TIME_OUT)
        @address_service.stub(:full_address_lookup).with(@search_result_id).and_return(response)
        expect{@address_service.populate_user_address_from_search_result_id!(@user_from_2000, @search_result_id)}.to raise_error(TotalCheckSearchResultIdExpiryException)
      end

      after :each do
        assert_that_user_details_were_not_changed
      end

      def assert_that_user_details_were_not_changed
        user = User.find(@user_from_2000.id)
        user.street_address.should == '51 Pitt St'
        user.suburb.should == 'Sydney'
        user.postcode.number.should == '2000'
      end
    end

    context 'response indicates success' do
      before :each do
        create(:postcode, :number => '2010')
        postcode = create(:postcode, :number => '3000')
        @user_from_3000 = create(:user, :street_address => '303 Collins St', :suburb => 'Melbourne', :postcode => postcode)
      end

      it 'should return true if dpid exists and status is OK' do
        time_address_validated_at = nil
        Timecop.freeze(DateTime.parse('2013-06-11 16:00:26 +1000')) do
          time_address_validated_at = Time.now
          @address_service.populate_user_address_from_search_result_id!(@user_from_3000, @search_result_id).should be true
        end
        assert_that_user_details_were_changed(time_address_validated_at)
      end

      def assert_that_user_details_were_changed(address_validated_at)
        user = User.find(@user_from_3000.id)
        user.street_address.should == '100 Commonwealth St'
        user.suburb.should == 'SURRY HILLS'
        user.postcode.number.should == '2010'
        user.address_validated_at.should == address_validated_at
      end
    end

    describe '#get_first_search_result_id' do
      it 'should return the first search result id' do
        @address_service.stub(:lookup_address_using_partial_address).and_return(JSON_SEARCH_RESULTS)
        search_result_id = @address_service.get_first_search_result_id('some address')
        search_result_id.should == '62f5d91f-c20a-4660-b0db-65a044758f5c--1'
      end
    end
  end

  JSON_RESPONSE_SUCCESS = <<'JSON'
    {"status":"OK","result":
      {"@type":"address_result__201301","barcode":"1301012122200020223011323310303020313","bsp":"010",
       "dpid":"78606894","postcode":"2010","state":"NSW","suburb":"SURRY HILLS","city":null,
       "country":"AUSTRALIA","email":null,"url":null,"abn":null,"anzsic":null,"headings":null,"gender":null,
       "lga":null,"ccd":null,"sla":null,"search_result_id":"168fee2b-9940-48ce-bc6b-5545257daa85--2",
       "listing_type":null,"listing_id":null,"formatted_address":"100 Commonwealth St, SURRY HILLS  NSW  2010",
       "building_name":null,"street_address":"100 Commonwealth St","street_number":"100","street_name":"Commonwealth",
       "street_suffix":null,"street_type":"St","subpremise":null,"phone_numbers":[],"primary_name":null,
       "secondary_name":null,"geo_lat":"-33.880478","geo_lon":"151.210895","is_postal":true,"is_listing":false,
       "is_new_listing":null,"contains_subpremises":false,"abn_status":null,"business_name":null,"main_heading":null},
    "search_date":"14-11-2013 15:36:20","search_parameters":{},"time_taken":417,
    "transaction_id":"d68941db-fc16-442b-8d5d-0e59dc8e0d03","root_transaction_id":"168fee2b-9940-48ce-bc6b-5545257daa85"}
JSON

  JSON_RESPONSE_TIME_OUT = <<'JSON'
    {"status":"BAD_REQUEST","result":null,"search_date":"20-11-2013 10:44:09","search_parameters":{},"time_taken":12,
      "response_message":"Could not locate Search Result for Index : 28219187-e639-47fc-9c60-d5a405280981--1",
      "transaction_id":"fa21bf3e-01b1-4320-aae9-b24e11e1782d"}
JSON

  JSON_SEARCH_RESULTS = <<'JSON'
    {"status":"OK","results":[{"@type":"address_search_result__201301","index":1,"postcode":null,"state":null,
     "suburb":null,"city":null,"country":null,"search_result_id":"62f5d91f-c20a-4660-b0db-65a044758f5c--1",
     "listing_type":null,"formatted_address":"Odo St, NORTH BEACH  WA  6020","street_address":null,"primary_name":null,
     "secondary_name":null,"is_postal":true,"is_listing":false,"contains_subpremises":true},
      {"@type":"address_search_result__201301","index":2,"postcode":null,"state":null,"suburb":null,"city":null,
      "country":null,"search_result_id":"62f5d91f-c20a-4660-b0db-65a044758f5c--2","listing_type":null,
      "formatted_address":"Odd St, HORSESHOE BEND  NSW  2320","street_address":null,"primary_name":null,
      "secondary_name":null,"is_postal":true,"is_listing":false,"contains_subpremises":true},
      {"@type":"address_search_result__201301","index":3,"postcode":null,"state":null,"suburb":null,"city":null,
      "country":null,"search_result_id":"62f5d91f-c20a-4660-b0db-65a044758f5c--3","listing_type":null,
      "formatted_address":"Odd St, MAITLAND  NSW  2320","street_address":null,"primary_name":null,"secondary_name":null,
      "is_postal":true,"is_listing":false,"contains_subpremises":true}],
      "search_date":"20-11-2013 12:26:20","search_parameters":{"include_paf":"true","include_listing":"true",
      "formatted_address":"Odo St"},"time_taken":26,"transaction_id":"62f5d91f-c20a-4660-b0db-65a044758f5c",
      "result_count":3}
JSON

end
