module DonationHelper
  include VanityHelper

  def show_all_amounts?(list_of_amounts)
    (list_of_amounts.count { |amount| amount.end_with?('*') }) == 0
  end

  def donation_method_tab_link(payment_type, text, options = {})
    link_to text, "##{payment_type}", options.merge("data-toggle" => "tab", :"data-payment-method" => "#{payment_type}")
  end
  
  def show_recurring_label(donation_module)
    donation_module.available_frequencies_for_select.count == 1 && 
      ['weekly', 'monthly', 'annual'].include?(donation_module.available_frequencies_for_select[0][1])
  end

end
