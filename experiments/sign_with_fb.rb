ab_test :sign_with_fb do
  description "Test the effect of sign with FB on petition module"
  alternatives :control, :experiment
  default :control
  metrics :money
end
