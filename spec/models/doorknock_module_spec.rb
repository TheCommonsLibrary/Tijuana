require File.expand_path(File.dirname(__FILE__) + "../../spec_helper")

def street_allocated_to(user)
  street = create(:street)
  StreetUserModule.create!(user: user, street: street, content_module: @doorknock, page: @page)
  street
end

describe DoorknockModule do

  before :each do
    @user = create(:user)
    @page = create(:page_with_parent)
    @email = nil
    @doorknock = create(:doorknock_module)
  end

  describe "take_action" do
    it 'should create user activity events' do
      UserActivityEvent.should_receive(:action_taken!).with(@user, @page, @doorknock, an_instance_of(StreetUserModule), nil, nil, nil).twice
      street1 = create(:street)
      street2 = create(:street)
      @doorknock.take_action(@user, @page, @email, {street_id: [street1.id, street2.id]})
    end

    it "should create StreetUserModules when successful" do
      street1 = create(:street)
      street2 = create(:street)
      @doorknock.take_action(@user, @page, @email, {street_id: [street1.id, street2.id]})

      street_user_module1 = StreetUserModule.find_by_street_id(street1.id)
      street_user_module1.user_id.should == @user.id
      street_user_module1.content_module_id.should == @doorknock.id

      street_user_module2 = StreetUserModule.find_by_street_id(street2.id)
      street_user_module2.user_id.should == @user.id
      street_user_module2.content_module_id.should == @doorknock.id
    end
    it "should collapse duplicate streets" do
      street = create(:street)
      @doorknock.take_action(@user, @page, @email, {street_id: [street.id, street.id]})
      StreetUserModule.count.should == 1
      street_user_module = StreetUserModule.last
      street_user_module.street_id.should == street.id
      street_user_module.user_id.should == @user.id
      street_user_module.content_module_id.should == @doorknock.id
    end
    it "should ignore blank street ids" do
      street = create(:street)
      @doorknock.take_action(@user, @page, @email, {street_id: [street.id, '']})
      StreetUserModule.count.should == 1
      street_user_module = StreetUserModule.last
      street_user_module.street_id.should == street.id
      street_user_module.user_id.should == @user.id
      street_user_module.content_module_id.should == @doorknock.id
    end

    it "should return false and not save if any street_user_modules are invalid" do
      unallocated_street = create(:street)
      other_user = create(:user)
      allocated_street = street_allocated_to(other_user)
      @doorknock.take_action(@user, @page, @email, {street_id: [unallocated_street.id, allocated_street.id]}).should == false
      StreetUserModule.where(street_id: unallocated_street.id).should_not be_present
    end
  end

  describe "invalid_street_user_modules" do
    it "should expose streets that are invalid (have already been taken)" do
      unallocated_street = create(:street)
      other_user = create(:user)
      allocated_street = street_allocated_to(other_user)

      @doorknock.take_action(@user, @page, @email, {street_id: [unallocated_street.id, allocated_street.id]})

      @doorknock.invalid_street_user_modules.count == 1
      @doorknock.invalid_street_user_modules.first.street.should == allocated_street
    end

  end


  describe "suburbs" do
    it "should return suburbs in alpha order" do
      create(:street, suburb_name: 'Zombieville')
      create(:street, suburb_name: 'Aardvarkville')
      create(:street, suburb_name: 'Mediocreville')

      @doorknock.suburb_names.should == ['Aardvarkville', 'Mediocreville', 'Zombieville']
    end
  end

  describe "ask_module_text" do
    it "should return the names and suburbs of the streets" do
      street1 = create(:street, name: 'Easy Street', suburb_name: 'Richville')
      street2 = create(:street, name: 'Battler Street', suburb_name: 'Howardville')
      @doorknock.take_action(@user, @page, @email, {street_id: [street1.id, street2.id]})
      @doorknock.ask_module_text.should == "Easy Street, Richville\nBattler Street, Howardville"
    end
  end
end
