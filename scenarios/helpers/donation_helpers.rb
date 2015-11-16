module OfflineDonationHelper
  def create_offline_donation(user, page, amount_in_dollars)
    visit new_admin_donation_path

    fill_in 'donation_user_id', with: user.id
    select 'Dummy Campaign Name', :from => 'campaign'
    fill_in 'donation_amount_in_dollars', with: amount_in_dollars
    select 'Bank Cheque', from: 'donation_payment_method'
    fill_in 'donation_identifier', with: '221b Baker Street'
  end

  def click_js_confirm(accept=true)
    page.execute_script("$.rails.confirm = function () { return #{!!accept}; };")
    page.execute_script("window.confirm = function(msg) { return #{!!accept}; }")
  end

  def find_transactions(donation)
    visit admin_transactions_path

    fill_in 'query', with: donation.amount_in_dollars
    click_button 'Search'

    page.should have_content(number_to_currency(donation.amount_in_dollars))
  end
end
