class ReadonlyDatabase < ActiveRecord::Base
  establish_connection "#{Rails.env}_readonly"
end