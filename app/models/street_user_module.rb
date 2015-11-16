class StreetUserModule < ActiveRecord::Base
  include ActsAsUserResponse

  belongs_to :street
  attr_accessor :page

  validate :uniqueness_of_street_id

  def uniqueness_of_street_id
    if StreetUserModule.where(street_id: street_id, content_module_id: content_module_id).count > 0
      errors.add(:base, "#{street.name}, #{street.suburb_name}, has been already been taken by another user.")
    end
  end
end