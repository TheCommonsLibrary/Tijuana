FactoryGirl.define do
  factory :donation_upgrade do |f|
    f.original_amount_in_cents 4000
    f.upgrade_amount_in_cents 1000
    f.donation { create(:recurring_donation) }
    f.content_module { create(:donation_upgrade_module) }
  end
end
