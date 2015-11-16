class WeeklyStatistics
  attr_reader :partial_name, :one_week_object, :six_month_object

  def initialize(partial_name, one_week_object, six_month_object)
    @partial_name = partial_name
    @one_week_object = one_week_object
    @six_month_object = six_month_object
  end
end