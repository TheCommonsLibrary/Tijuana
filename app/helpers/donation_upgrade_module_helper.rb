module DonationUpgradeModuleHelper
  def amount_display(donation)
    number_to_currency donation.amount_in_cents / 100, strip_insignificant_zeros: true
  end

  def recurring_period(donation)
    case donation.frequency
    when "weekly"  then "week"
    when "monthly" then "month"
    when "annual"  then "year"
    end
  end

  def upgrade_amounts(donation)
    DonationUpgradeModule::DONATION_UPGRADE_AMOUNTS[donation.frequency]
  end
end
