ab_test :personalised_amounts_v4 do
  description "Next iteration of testing relative amounts"
  alternatives :static, :relative, :relative_with_adjustments, :relative_with_average_check
  metrics :money
  default :static
end
