require File.dirname(__FILE__) + '/../spec_helper.rb'

describe MerchModule do
  describe '#update_action_attributes_and_validate' do
    before(:each) do
      subject.custom_fields_as_yaml = custom_fields_yaml
      subject.user_notifier = Proc.new{|level, title, message| 'notifies user' }
      subject.donation #force init of custom fields
    end

    it 'should add errors to donation and postal_address' do
      params = {postal_address: {street_address: '1 james st', search_outcome: 'manual'}, donation: {quantity: '1x'}}
      subject.update_action_attributes_and_validate(params)
      subject.postal_address.should have(1).error_on(:postcode_number)
      subject.postal_address.should have(1).error_on(:suburb)
      subject.postal_address.street_address.should == '1 james st'
      subject.donation.errors.should_not be_blank
    end

    it 'should not add errors to postal_address' do
      create(:postcode, number: '2010')
      params = {:postal_address => {
        :street_address => "1 James st", :postcode_number => '2010', :suburb => 'Surry Hills',
        :search_outcome => 'manual', :state => 'NSW'},
                :donation => {}}
      subject.update_action_attributes_and_validate(params)
      subject.postal_address.errors.should be_blank
    end
  end

  describe 'disable paypal by default' do
    context 'on initialize' do
      it 'should set disable_paypal to true' do
        MerchModule.new().paypal_disabled?.should be true
      end
    end
  end


  describe 'address validation' do
    let(:user) { create(:user) }
    let(:page) { create(:page_with_parent) }

    before :each do
      create(:postcode_of_circular_quay)
      subject.stub(:call_parent_class_take_action).and_return(true)
      @params = {
        :donation => {
          :custom_amount_in_dollars => '',
          :payment_method => "credit_card",
          :card_number => "4012888888881881",
          :name_on_card => "Test User",
          :card_expiry_month => "01",
          :card_expiry_year => "2016",
          :card_cvv => "123",
          :amount_in_dollars => "100.0",
          :quick_donation => '0',
        },
        :postal_address => {
          :search_outcome => "", 
          :address_search => "", 
          :street_address => "", 
          :suburb => "", 
          :postcode_number => ""
        }
      }
      subject.custom_fields_as_yaml = custom_fields_yaml
    end

    it 'should have no address errors if quantity = NONE' do
      @params[:donation][:quantity] = 'NONE'
      subject.custom_fields_as_yaml = custom_fields_yaml
      subject.update_action_attributes_and_validate(@params)

      subject.take_action(user, page, nil, @params)
      subject.postal_address.errors.should be_blank
    end

    it 'should produce address validation error if quantity specified' do
      subject.custom_fields_as_yaml = custom_fields_yaml
      @params[:donation][:quantity] = '1x'
      subject.update_action_attributes_and_validate(@params)

      subject.take_action(user, page, nil, @params)
      subject.postal_address.errors.should_not be_blank
    end

    it 'should produce address validation error if quantity not configured' do
      subject.custom_fields_as_yaml = custom_fields_no_quantity_yaml
      subject.update_action_attributes_and_validate(@params)

      subject.take_action(user, page, nil, @params)
      subject.postal_address.errors.should_not be_blank
    end
  end

  describe '#take_action' do

    let(:user) { create(:user) }
    let(:page) { create(:page_with_parent) }

    before :each do
      @params = build_params
      create(:postcode_of_circular_quay)
      subject.stub(:call_parent_class_take_action).and_return(true)
    end

    describe 'manual address lookup mode' do
      it 'should return false if superclass method returns false' do
        subject.stub(:call_parent_class_take_action).and_return(false)
        subject.update_action_attributes_and_validate(@params)
        result = subject.take_action(user, page, nil, @params)
        result.should be false
      end

      it 'should return true if valid postal_address' do
        subject.update_action_attributes_and_validate(@params)
        result = subject.take_action(user, page, nil, @params)
        result.should be true
      end

      it 'should return false if invalid postal_address' do
        @params[:postal_address][:suburb] = nil
        subject.update_action_attributes_and_validate(@params)
        result = subject.take_action(user, page, nil, @params)
        result.should be false
      end

      it 'should show errors if invalid postcode entered' do
        @params[:postal_address][:postcode_number] = '9999'
        subject.update_action_attributes_and_validate(@params)
        result = subject.take_action(user, page, nil, @params)
        subject.postal_address.errors[:postcode_number][0].should == '^Please enter a valid postcode'
        result.should be false
      end

    end

    describe 'address lookup search mode' do
      before :each do
        @search_result_id = '1'
        subject
        .send(:address_service)
        .stub(:populate_user_address_from_search_result_id!)
        .with(user, @search_result_id)
        @params[:postal_address][:search_outcome] = @search_result_id
      end

      it 'should return false if superclass method returns false' do
        subject.stub(:call_parent_class_take_action).and_return(false)
        subject.update_action_attributes_and_validate(@params)
        result = subject.take_action(user, page, nil, @params)
        result.should be false
      end

      it 'should return true if valid postal_address' do
        subject.update_action_attributes_and_validate(@params)
        result = subject.take_action(user, page, nil, @params)
        result.should be true
      end

      it 'should return false if invalid postal_address' do
        subject
        .send(:address_service)
        .stub(:populate_user_address_from_search_result_id!)
        .with(user, @search_result_id)
        .and_raise(Exception)
        subject.update_action_attributes_and_validate(@params)
        result = subject.take_action(user, page, nil, @params)
        result.should be false
      end

      it 'should update search result id using the search address input value after a search result id expires' do
        new_id = 'fa21bf3e-01b1-4320-aae9-b24e11e1782d'
        subject.stub(:quantity_selected?).and_return(true)
        subject.update_action_attributes_and_validate(@params)
        subject.send(:address_service).stub(:populate_user_address_from_search_result_id!)
        .with(user, @search_result_id).and_raise(TotalCheckSearchResultIdExpiryException)
        subject.send(:address_service).stub(:populate_user_address_from_search_result_id!)
        .with(user, new_id)
        subject.send(:address_service).stub(:get_first_search_result_id)
        .with(subject.postal_address.address_search).and_return(new_id)
        result = subject.take_action(user, page, nil, @params)
        result.should be true
      end
    end
  end

  def custom_fields_no_quantity_yaml
    <<YAML
---
:form_fields:
- :name: item
  :type: select
  :label: Select your item below
  :options:
  - :text: -- Select your size --
    :value: 
  - :text: Mens Small
    :value: M-S
    :minimum_donation: 25
  - :text: Mens Medium
    :value: M-M
YAML
  end

  def custom_fields_yaml
    <<YAML
---
:form_fields:
- :name: quantity
  :type: select
  :label: Books to receive
  :required: true
  :options:
  - :text: I just want to donate
    :value: NONE
  - :text: 1 x Book ($20 min)
    :value: 1x
    :minimum_donation: 20
  - :text: 2 x Books ($40 min)
    :value: 2x
    :minimum_donation: 40
  - :text: 3 x Books ($60 min)
    :value: 3x
    :minimum_donation: 60
  - :text: 4 x Books ($80 min)
    :value: 4x
    :minimum_donation: 80
YAML
  end

  def build_params
    {
      :postal_address => {
        :street_address => "51 Pitt St", :postcode_number => '2000', :suburb => 'Sydney',
        :search_outcome => 'manual', :state => 'NSW'},
      :donation => {
        :custom_amount_in_dollars => '',
        :payment_method => "credit_card",
        :card_number => "4012888888881881",
        :name_on_card => "Test User",
        :card_expiry_month => "01",
        :card_expiry_year => "2016",
        :card_cvv => "123",
        :amount_in_dollars => "100.0",
        :quick_donation => '0'
      }
    }
  end
end
