module ImageShareModuleHelper
  def zero_when_blank(val)
    val.blank? ? 0 : val.to_i
  end
end
