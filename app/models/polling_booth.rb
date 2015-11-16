class PollingBooth < ActiveRecord::Base
  belongs_to :postcode
  belongs_to :electorate
  validates :electorate, :postcode, :presence => true
  validates :latitude, uniqueness: {scope: :longitude}

  acts_as_mappable :default_units => :kms,
                   :default_formula => :sphere,
                   :lat_column_name => :latitude,
                   :lng_column_name => :longitude

  def electorates
    [electorate]
  end

  def hours
    [{from_date: '2016-07-02', to_date: '2016-07-02', from_time: '8:00', to_time: '18:00'}]
  end
end
