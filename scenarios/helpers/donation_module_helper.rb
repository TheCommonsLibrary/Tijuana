module DonationModuleHelper

  DEFAULTS = {
      card_number: '4111111111111111',
      name_on_card: 'Carduser Name-Guy',
      card_cvv: '343',
      card_expiry_month: Date.today.month.to_s.rjust(2, '0'),
      card_expiry_year: "#{Date.today.year + 1}"
  }

  def donate(params = {})
    fill_in 'donation_card_number', with: mandatory_value(params, :card_number)
    fill_in 'donation_name_on_card', with: mandatory_value(params, :name_on_card)
    select mandatory_value(params, :card_expiry_month), :from => 'donation_card_expiry_month'
    select mandatory_value(params, :card_expiry_year), :from => 'donation_card_expiry_year'
    fill_in 'donation_card_cvv', with: mandatory_value(params, :card_cvv)
    find("button[data-amount='#{params[:amount]}']").click if params[:amount]
    if (params[:custom_amount_in_dollars])
      find("button[data-amount='other']").click
      find('#credit input[name="donation[custom_amount_in_dollars]"]').set(params[:custom_amount_in_dollars])
    end
    select(params[:frequency], :from => 'donation-frequency-credit') if params[:frequency]
    find('.ask-submit-button').click
  end

  private

  def mandatory_value(params, key)
    params[key] || DEFAULTS[key]
  end
end

RSpec.configuration.include DonationModuleHelper, :type => :feature