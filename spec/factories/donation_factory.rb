FactoryGirl.define do
  factory(:donation) do |f|
    f.user              { create(:user) }
    f.page              { create(:page_with_parent) }
    f.content_module    { create(:donation_module) }
    f.amount_in_cents   { 3000 }
    f.payment_method    { "credit_card" }
    f.frequency         { "one_off" }
    f.card_type         { "visa" }
    f.card_number       { PaymentGateways::CARD_SUCCESS }
    f.name_on_card      { "Someone Cardholder" }
    f.card_expiry_year  { Time.now.year }
    f.card_expiry_month { Time.now.month }
    f.card_cvv          { 123 }
  end
  
  factory(:donation_without_validation, :parent => :donation) do |r|
    r.to_create do |instance|
      instance.save(:validate => false)
    end
  
  end
  
  factory(:recurring_donation, :parent => :donation) do |r|
    r.frequency      { "weekly" }
  end
  
  factory(:flagged_donation, :parent => :recurring_donation) do |r|
    r.flagged_since   { Time.now }
    r.flagged_because { "Y U NO PAY US" }
  end
  
  
  
  factory(:paypal_donation, :class => Donation) do |f|
    f.user              { create(:user) }
    f.page              { create(:page_with_parent) }
    f.content_module    { create(:donation_module) }
    f.amount_in_cents   { 1000 }
    f.payment_method    { "paypal" }
    f.frequency         { "one_off" }
    f.card_type         { nil }
    f.card_number       { nil }
    f.name_on_card      { nil }
    f.card_expiry_year  { nil }
    f.card_expiry_month { nil }
    f.card_cvv          { nil }
    f.updated_at        { generate(:time) }
    f.created_at        { generate(:time) }
  end
  

end
