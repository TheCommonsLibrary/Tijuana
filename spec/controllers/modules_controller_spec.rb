require File.expand_path(File.dirname(__FILE__) + "../../spec_helper")

describe ModulesController do

  describe "#streets" do
    it "should return as JSON all the streets which have not been taken for the given suburb in the given campaign" do

      example_result = [create(:street), create(:street)]
      Street.should_receive(:unallocated_for_content_module_id_and_suburb).with('content module id', 'suburb name').and_return(example_result)

      get :streets, module_id: 'content module id', suburb_name: 'suburb name'
      json = JSON.parse(response.body)
      json.length.should == 2
      json[0]['id'].should == example_result[0].id
      json[0]['name'].should == example_result[0].name
      json[1]['id'].should == example_result[1].id
      json[1]['name'].should == example_result[1].name

    end
  end
end
