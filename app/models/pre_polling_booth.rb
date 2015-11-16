class PrePollingBooth < ActiveRecord::Base
  belongs_to :postcode
  has_and_belongs_to_many :electorates, -> { uniq }
  validates :postcode, presence: true
  acts_as_mappable :default_units => :kms,
                   :default_formula => :sphere,
                   :lat_column_name => :latitude,
                   :lng_column_name => :longitude
  serialize :hours, Array
  
  def ordered_hours
    hours.sort_by{|h| h[:from_date] }
  end
end
