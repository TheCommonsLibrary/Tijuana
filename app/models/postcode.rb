class Postcode < ActiveRecord::Base
  VALID_POSTCODE_REGEX = /\A\d\d\d\d\z/
  has_many  :users

  has_many :mps, through: :electorates
  has_many :senators, through: :regions

  has_and_belongs_to_many :electorates
  has_and_belongs_to_many :regions
  acts_as_mappable :default_units => :kms,
                   :default_formula => :sphere,
                   :lat_column_name => :latitude,
                   :lng_column_name => :longitude

  validates :number, :numericality => { :only_integer => true, :greater_than_or_equal_to => 0, :less_than => 10_000, :message => "%{value} is not a number!" }
  validates :number, :format => { :with => VALID_POSTCODE_REGEX, :message => "%{value} is not a valid format!" }
  validates :longitude, :inclusion => { :in => 96.8315..159.1 }
  validates :latitude, :inclusion => { :in => -44..-10 }

  extend RemoveIdProtection

  def electorates_by_jurisdiction_code jurisdiction_code
    electorates.joins(:jurisdiction).where(:jurisdictions => {:code => jurisdiction_code})
  end

  def regions_by_jurisdiction_code jurisdiction_code
    regions.joins(:jurisdiction).where(:jurisdictions => {:code => jurisdiction_code})
  end

  def self.add_leading_zero_if_three_digits(number)
    if !number.nil? && number.length == 3
      return "0#{number}"
    end
    return number
  end

  def most_populous_electorate_by_jurisdiction_id(jurisdiction_id)
    electorates.where('jurisdiction_id = ?', jurisdiction_id).order('population desc').limit(1).first
  end
end
