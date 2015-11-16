ab_test :amounts_shown_on_mobile do
  description "How many shown amounts on mobile are the most effective?"
  alternatives :subset, :all
  metrics :money
  default :subset
end
