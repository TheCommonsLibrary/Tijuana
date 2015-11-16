require File.expand_path(File.dirname(__FILE__) + "../../spec_helper")

describe StreetUserModule do

  def street_allocated_to(user)
    street = create(:street)
    StreetUserModule.create!(user: user, street: street, content_module: @content_module, page: @page)
    street
  end

  describe "validation" do

    before :each do
      @user = create(:user)
      @page = create(:page_with_parent)
      @email = nil
      @content_module = create(:doorknock_module)
    end

    it "should detect duplicate streets for a module" do
      other_user = create(:user)
      street = street_allocated_to(other_user)
      street_user_module = StreetUserModule.new(user: @user, street: street, content_module: @content_module, page: @page)
      street_user_module.should_not be_valid
      street_user_module.errors.full_messages.first.should == "#{street.name}, #{street.suburb_name}, has been already been taken by another user."
    end
  end


end
