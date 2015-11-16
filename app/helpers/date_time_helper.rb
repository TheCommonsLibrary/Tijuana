module DateTimeHelper
  def remove_second_and_time_zone(date_time)
    date_time.strftime("%d-%m-%Y %H:%M") 
  end
end
