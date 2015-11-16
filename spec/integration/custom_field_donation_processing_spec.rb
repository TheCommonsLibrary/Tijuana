require File.dirname(__FILE__) + '/../spec_helper.rb'

describe 'Processing donations with custom fields' do

  before(:each) do
    @donation_module = build(:donation_module, eligible_for_personalised_donation_tests: false)
    @donation_module.frequency_options = {'one_off' => 'hidden', 'weekly' => 'default', 'monthly' => 'hidden', 'annual' => 'hidden'}
    @donation_module.custom_fields_as_yaml = CUSTOM_FIELDS_YAML
    @donation_module.save!
    @user = create(:user, email: 'noone@example.com')
    @page = create(:page_with_parent)
    @donation_module.stub(:quickdonate_cookie_for?).and_return(false)
  end

  describe 'custom field option is missing' do
    it "should process the recurring payment and update the donation record" do
      donation_params = {:donation => attributes_for(:donation, :card_number => PaymentGateways::CARD_SUCCESS, quantity: '2', frequency: 'weekly')}

      Timecop.freeze(Time.local(2013, 06, 01, 10, 0, 0)) do
        @donation_module.update_action_attributes_and_validate(donation_params)
        @donation_module.take_action(@user, @page, @email, donation_params).should == true
      end

      donation = @donation_module.donation
      donation.last_donated_at.should == Time.local(2013, 06, 01, 10, 0, 0)
      @donation_module.custom_fields_as_yaml = CUSTOM_FIELDS_NONE_OPTION_YAML
      @donation_module.save!

      donation_service = DonationService.new
      Timecop.freeze(Time.local(2013, 06, 21, 10, 0, 0)) do
        donation_service.trigger_due_periodic_payments! "weekly", Time.now - (24*7).hours, 1.hour # (24*7).hours = 1 week regardless of daylight savings
      end

      donation.reload
      donation.last_donated_at.should == Time.local(2013, 06, 21, 10, 0, 0)
    end
  end

  CUSTOM_FIELDS_NONE_OPTION_YAML = <<YAML
---
:form_fields:
- :name: quantity
  :type: select
  :label: Books to receive
  :required: true
  :options:
  - :text: I just want to donate
    :value: NONE
YAML

  CUSTOM_FIELDS_YAML = <<YAML
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
    :value: '1'
    :minimum_donation: 20
  - :text: 2 x Books ($40 min)
    :value: '2'
    :minimum_donation: 40
  - :text: 3 x Books ($60 min)
    :value: '3'
    :minimum_donation: 60
  - :text: 4 x Books ($80 min)
    :value: '4'
    :minimum_donation: 80
YAML
end
