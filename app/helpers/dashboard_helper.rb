module DashboardHelper
  def mask_card_number(card_number)
    #masks all but the last 4 characters of credit card with 'X' and splits into groups of 4 characters
    card_number.blank? ? "XXXX XXXX XXXX XXXX" : card_number.last(4).rjust(16,"X").gsub(/(.{4})(?=.)/, '\1 \2')
  end

  def month_options
    options = []
    ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"].each_with_index do |item,idx|
      options << [item,idx+1]
    end
    options
  end

  def year_options
    year = Date.today.year
    (year..year+6).map(&:to_s).map{ |y| [y,y] }
  end
end
