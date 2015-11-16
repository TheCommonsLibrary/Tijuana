module MakeRecurringHelper
  def display_make_recurring?(page)
    page.previous.try(:make_recurring_enabled?) &&
      preceding_donation.present? &&
      preceding_donation.by_credit_card? &&
      just_donated_user.active_recurring_donations.blank?
  end

  def make_recurring_button_text(donation_module)
    amount = preceding_donation.amount_in_dollars
    max = AppConstants.max_make_recurring_amount
    amount_or_max = amount > max ? max : amount
    amount_text = number_to_currency(amount_or_max).gsub(/\.00$/, "").to_s
    template = donation_module.make_recurring_button
    template.gsub(/{amount}/, amount_text)
  end

  private

  # Patched to false in scenario_helper as scenarios are on http
  def use_secure_cookies?
    !Rails.env.development?
  end

  def just_donated_user
    preceding_donation.try(:user)
  end

  def preceding_donation
    @preceding_donation ||= Donation.find(session[:action_id]) if session[:action_id].present?
  end
end
