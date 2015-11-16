class PostalAddress
  include ActiveModel::Validations

  attr_accessor :street_address, :postcode_number, :suburb, :address_search, :search_outcome, :state

  with_options :if => -> { manual_mode? } do |manual|
    manual.validates :street_address, :presence => true
    manual.validate :validate_postcode
    manual.validates :suburb, :presence => true
  end

  def initialize(attributes = {})
    attributes.each do |name, value|
      send("#{name}=", value)
    end
  end

  def manual_mode?
    self.search_outcome == 'manual'
  end

  private

  def validate_postcode
    p = Postcode.add_leading_zero_if_three_digits(postcode_number)
    if Postcode.find_by_number(p).blank?
      self.errors.add(:postcode_number, '^Please enter a valid postcode')
    end
  end
end
