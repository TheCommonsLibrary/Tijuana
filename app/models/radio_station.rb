class RadioStation < ActiveRecord::Base

  extend RemoveIdProtection

  has_many :radio_shows

  acts_as_mappable :default_units => :kms,
                   :default_formula => :sphere,
                   :lat_column_name => :latitude,
                   :lng_column_name => :longitude

  validates :state, :inclusion => { :in => ["NSW", "QLD", "WA", "SA", "VIC", "NT", "TAS", "ACT"] }
  validates :broadcast_radius, :numericality => true

end
#RadioShow.where("(from_time <= ? AND  to_time >= ?) or (from_time between ? and ?) ",Time.now, Time.now, Time.now, (Time.now + 1.hour));