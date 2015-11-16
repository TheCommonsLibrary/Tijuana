module TechMailerHelper
  def value_to_percentage_string(value)
    return number_to_percentage(value * 100, precision: 2) unless value.instance_of? String
    return value
  end

  def divide_and_return_as_percentage(numerator, denominator)
    if denominator != 0
      number_to_percentage((numerator / denominator.to_f * 100), precision: 2)
    else
      "#{numerator}/#{denominator}"
    end
  end
end
