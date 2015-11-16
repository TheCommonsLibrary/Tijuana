class VisionSurveyDataByPostcode < ActiveRecord::Base
  belongs_to :postcode

  def method_missing(method_id, *args, &block)
    if method_id.to_s =~ /^approximate_(.+)$/
      approximate(self[$1])
    else
      super
    end
  end

  def respond_to?(method_id, include_private = false)
    if method_id.to_s =~ /^approximate_[\w]+/
      true
    else
      super
    end
  end

  def approximate(attribute_value)
    if attribute_value > 0
      place_value = 10**Math.log10(attribute_value).floor
      attribute_value - (attribute_value % place_value)
    else
      attribute_value
    end
  end
end