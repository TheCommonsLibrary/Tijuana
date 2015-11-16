require File.dirname(__FILE__) + "/scenario_helper.rb"

=begin
# payment gateway test: donate once with no quick donate
describe "user purchases merch", type: :feature, js: true do

  before(:each) do
    @campaign = create(:campaign)
    @page_sequence = create(:page_sequence, campaign: @campaign)
    @page = create(:page, page_sequence: @page_sequence, position: 1)
    @page2 = create(:page, page_sequence: @page_sequence, position: 2, name: "Thanks for taking action")
    @postcode = create(:postcode, number: '2010')
    @merch_module = create(:merch_module, use_fixed_amounts: true)
    @merch_module.frequency_options = {'one_off' => 'default', 'weekly' => 'optional', 'monthly' => 'optional', 'annual' => 'optional'}
    @merch_module.save!
    @link = create(:content_module_link, page: @page, content_module: @merch_module, layout_container: :sidebar)
    @user = create(:user)

    @old_USE_PROVIDER_GATEWAY = ENV['USE_PROVIDER_GATEWAY']
    ENV['USE_PROVIDER_GATEWAY'] = "true"
    
    @conventional_form_url = page_path(id: @page, page_sequence_id: @page_sequence, campaign_id: @campaign)
  end

  after(:each) do
    ENV['USE_PROVIDER_GATEWAY'] = @old_USE_PROVIDER_GATEWAY
  end

  it { existing_user_with_custom_fields 'Donate Once' }

  private

  def existing_user_with_custom_fields(frequency)
    @merch_module.custom_fields = {
        form_fields: [
          {
            name: 'item',
            type: 'select',
            label: 'Select your item below',
            required: true,
            options: [
                {text: '-- Select your item --', value: ''},
                {text: 'A Book', value: 'BOOK', minimum_donation: 30, requires: 'delivery_method'}
            ]
          },
          {
            name: 'delivery_method',
            type: 'text_field',
            label: 'Enter delivery method',
          },
        ]
    }
    @merch_module.save!

    visit @conventional_form_url
    fill_in 'user_email', with: @user.email
    user_lookup_complete
    select "A Book", from: 'donation[item]'
    fill_in 'donation[delivery_method]', with: "Snail Mail"
    fill_in 'donation[custom_amount_in_dollars]', with: '40'
    fill_in_autocomplete('Update your Address*', '104 Commonwealth St, SURRY HILLS  NSW  2010')
    click_on_first_autocomplete_item

    should_accept_credit_card_payment(frequency)
    donation = Donation.find_by_user_id(@user.id)
    expect(donation.item).to eq('BOOK')
    expect(donation.delivery_method).to eq('Snail Mail')
  end

  def should_accept_credit_card_payment(frequency)
    donate(frequency: frequency)
    expect(page).to have_content(@page2.name)
  end
end
=end
