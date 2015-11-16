require File.expand_path(File.dirname(__FILE__) + "../../spec_helper")

def create_street_allocated_for(content_module, suburb_name = "Upper Richville")
  allocated_street = create(:street, suburb_name: suburb_name)
  page = create(:page_with_parent)
  StreetUserModule.create!(content_module: content_module, street: allocated_street, user: @user, page: page)
  allocated_street
end

describe Street do

  before :each do
    @user = create(:user)
    @my_module = create(:doorknock_module)
    @other_module = create(:doorknock_module)
  end

  describe ".unallocated_for" do

    it "should return all the streets that have not been allocated to given module" do
      unallocated_street = create(:street)
      street_allocated_for_other_module = create_street_allocated_for(@other_module)
      create_street_allocated_for(@my_module)

      Street.unallocated_for_content_module_id(@my_module.id).should == [unallocated_street, street_allocated_for_other_module]
    end

  end

  describe ".unallocated_for_content_module_id_and_suburb" do

    it "should return all the streets that have not been allocated to given module in a particular suburb in alpha order" do
      unallocated_street = create(:street, name: 'ZZZZZZZombie', suburb_name: "Here")
      create(:street, suburb_name: "Elsewhere")

      street_allocated_for_other_module = create_street_allocated_for(@other_module, "Here")
      create_street_allocated_for(@other_module, "Elsewhere")

      Street.unallocated_for_content_module_id_and_suburb(@my_module.id, 'Here').should == [street_allocated_for_other_module, unallocated_street]
    end
  end

end
