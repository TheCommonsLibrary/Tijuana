ab_test :automated_daisy_chain do
  description "Does an automated daisy chain increase shares and/or donations"
  alternatives :control, :treatment
  metrics :money, :shares
  default :control
end
