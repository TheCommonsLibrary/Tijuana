module FormattingHelper

  def pretty_date(date)
    if not date 
      ""
    else
      raw(date.strftime "%A, %e %B %Y")
    end
  end

  def pretty_time(time, date)
    return '' if time.blank?
    str_time = '%04d'% time
    t = DateTime.new(date.year, date.month, date.day, str_time[0,2].to_i, str_time[2,4].to_i)
    t.strftime('%l:%M %P')
  end

end
